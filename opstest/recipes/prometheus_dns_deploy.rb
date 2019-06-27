# ---------------------------------------------------
#  Environment variables to set before running:
#  - SCRAPE_DNS_NAMES (csv list of dns addresses)
# ---------------------------------------------------

# use the "aws_opsworks_app" databag to iterate thru apps
search("aws_opsworks_app").each do |app|

    # find the (1) instance this recipe is being executed on and (2) its relevant layers
    instance = search("aws_opsworks_instance", "self:true").first
    Chef::Log.info("****** Instance '#{instance['instance_id']}' has the public IP '#{instance['public_ip']}' ******")
    layers = search("aws_opsworks_layer").select do |layer|
        instance[:layer_ids].include? layer[:layer_id]
    end
    # assume the convention that each instance is only associated to one layer
    instance_layer = layers.first
    if instance_layer[:shortname] == app[:shortname]
        # build app url we'll use to read & clone the repo
        app_env = app[:environment]

        # we assume that the "SCRAPE_DNS_NAMES" environment variable is provided as a csv string
        scrape_dns_names_list = app_env[:SCRAPE_DNS_NAMES].split(',')

        # -------------------------
        # setup prometheus.yml file
        # -------------------------
        prometheus_folder = "prometheus"
        prometheus_config_filename = "prometheus.yml"
        template "/home/ubuntu/#{prometheus_folder}/#{prometheus_config_filename}" do
            source "prometheus.yml.erb"
            mode "0755"
            owner "ubuntu"
            group "ubuntu"
            variables(scrape_dns_names_list: scrape_dns_names_list)
            action :create
        end

        # ----------------------------------
        # restart prometheus with new config
        # ----------------------------------
        bash "restart_prometheus" do
            user "ubuntu"
            group "ubuntu"
            cwd "/home/ubuntu"
            environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
            code <<-EOH
                # try to set up the PATH variable for nvm stuff
                export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
                echo $PATH
                
                # restart the prometheus process so the new config yml is picked up
                pm2 restart prometheus
            EOH
        end
    end
end
