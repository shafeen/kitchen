# ----------------------------------------------------------------------
#
# Note: you must have an nginx app running on port:80 !
#
# Environment variables to set before running:
# ============================================
# - SERVER_NAMES : comma delimited list of server names
# - CERTBOT_EMAIL : email address to use when registering certbot certs
#
# ----------------------------------------------------------------------


# use the "aws_opsworks_app" databag to iterate thru apps
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

    # prepare list of app environment variables for later use
    app_env = app[:environment]

    # ---------------------------------------------------------------
    # only run recipe for apps whose shortnames match instance layer!
    # ---------------------------------------------------------------
    if instance_layer[:shortname] == app[:shortname]
        Chef::Log.info("****** Instance layer and app shortnames '#{instance_layer[:shortname]}' match! ******")
        Chef::Log.info("****** Running recipe for app shortname: '#{app[:shortname]}' url: '#{app[:app_source][:url]} ******")


        # ------------------------------------------------------------
        # Following the ubuntu 18 nginx certbot instructions found below:
        # https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx
        # ------------------------------------------------------------

        # Install Certbot PPA
        apt_update 'update'
        package 'software-properties-common' do
            action :install
        end
        ['universe', 'ppa:certbot/certbot'].each do |repository_uri|
            bash "adding apt repository #{repository_uri}" do
                user 'root'
                group 'root'
                code <<-EOH
                    add-apt-repository #{repository_uri}
                EOH
            end
        end
        apt_update 'update'

        # Install Certbot
        ['certbot', 'python-certbot-nginx'].each do |package_name|
            package package_name do
                action :install
            end
        end

        # Choose how to run Certbot --> NOTE: nginx only
        server_names = app_env[:SERVER_NAMES]
        certbot_email = app_env[:CERTBOT_EMAIL]
        if !server_names || !certbot_email
            raise 'App environment variables SERVER_NAMES, CERTBOT_EMAIL must be set!'
        end
        bash "install_certbot_certificates_and_redirect_to_ssl" do
            user 'root'
            group 'root'
            code <<-EOH
                certbot --nginx -n -d #{server_names} --agree-tos --email #{certbot_email} --redirect
            EOH
        end


        # TODO: add Certbot auto renewal script
        # <add script here>

    end
end