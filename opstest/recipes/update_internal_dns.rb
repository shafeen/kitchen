# ---------------------------------------------------
#
#  This recipe will add the newly launched instance's internal ip address to
#  its app's desired internal hosted zone (aka internal DNS domain in route 53).
#
#  This recipe will also delete the ip address from the internal DNS domain
#  if it detects "shutdown" as the opsworks command.
#
#  A load balancer will be able to use the internal DNS to figure out the server
#  instances to round robin load balance between.
#
#  Environment variables to set from the "app" environment variables:
#  - R53_AWS_ACCESS_KEY_ID                     ------.
#  - R53_AWS_SECRET_ACCESS_KEY                 ------|----> Needed for AWS access (set on app)
#  - R53_AWS_REGION (default: "us-west-2")     ------'
#  - R53_HOSTED_ZONE_ID
#  - SUBDOMAIN_FOR_RECORD_SET (desired subdomain name to go under the hosted zone domain)
#  - RECORD_SET_TTL (optional: defaults to 300s)
#
#  Optional environmental varibles
#  - DNS_UPDATE_USE_PUBLIC_IP -- must be set to 'y' otherwise treated as false
#
#  Variables extracted from "instance" being launched (no need to set)
#  - INSTANCE_INTERNAL_IP (no need to set, will be extracted)
#
#  TODO: add an instance startup/shutdown hook for DNS cleanup
# ---------------------------------------------------

# use the "aws_opsworks_app" databag to iterate thru apps to find the current one
search("aws_opsworks_app").each do |app|

    # find the (1) instance this recipe is being executed on and (2) its relevant layers
    instance = search("aws_opsworks_instance", "self:true").first
    Chef::Log.info("****** Instance '#{instance['instance_id']}' has the private IP '#{instance['private_ip']}' ******")
    layers = search("aws_opsworks_layer").select do |layer|
        instance[:layer_ids].include? layer[:layer_id]
    end

    # assume each instance is only associated to one layer for simplicity
    instance_layer = layers.first

    # get command from the opsworks "Command Data Bag"
    command = search("aws_opsworks_command").first
    Chef::Log.info("****** The command's type is '#{command['type']}' sent at '#{command['sent_at']}' ******")

    # ---------------------------------------------------------------
    # only run recipe for apps whose shortnames match instance layer!
    # ---------------------------------------------------------------
    if instance_layer[:shortname] == app[:shortname]
        Chef::Log.info("****** Instance layer and app shortnames '#{instance_layer[:shortname]}' match! ******")
        Chef::Log.info("****** Running recipe for app shortname: '#{app[:shortname]}' url: '#{app[:app_source][:url]} ******")

        temp_script_folder = "/tmp/internal_dns_updater"
        app_env = app[:environment]
        dns_update_type = if command['type']=="shutdown" then "DELETE" else "CREATE" end
        use_public_ip = if app_env[:DNS_UPDATE_USE_PUBLIC_IP]==='y' then true else false end

        remote_directory temp_script_folder do
            owner "ubuntu"
            group "ubuntu"
            mode "0755"
            source "internal_dns_updater"
            action :create
        end

        bash "update_internal_dns_script" do
            user "ubuntu"
            group "ubuntu"
            cwd "/home/ubuntu"
            environment ({
                'HOME' => '/home/ubuntu', 'USER' => 'ubuntu',
                'AWS_ACCESS_KEY_ID' => app_env[:R53_AWS_ACCESS_KEY_ID],
                'AWS_SECRET_ACCESS_KEY' => app_env[:R53_AWS_SECRET_ACCESS_KEY],
                'AWS_REGION' => app_env[:R53_AWS_REGION],
                'R53_HOSTED_ZONE_ID' => app_env[:R53_HOSTED_ZONE_ID],
                'SUBDOMAIN_FOR_RECORD_SET' => app_env[:SUBDOMAIN_FOR_RECORD_SET],
                'RECORD_SET_TTL' => app_env[:RECORD_SET_TTL],
                'INSTANCE_INTERNAL_IP' => if use_public_ip then instance['public_ip'] else instance['private_ip'] end,
                'DNS_UPDATE_TYPE' => dns_update_type,
                'TMP_SCRIPT_FOLDER' => temp_script_folder
            })
            code <<-EOH
                # try to set up the PATH variable for nvm stuff
                export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
                echo $PATH
                
                # set up npm script dependencies and run script
                cd $TMP_SCRIPT_FOLDER && npm i && node internal_dns_updater.js
            EOH
        end

        remote_directory temp_script_folder do
            owner "ubuntu"
            group "ubuntu"
            action :delete
        end

    end

end