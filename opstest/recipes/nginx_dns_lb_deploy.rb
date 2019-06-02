# ---------------------------------------------------
#  Environment variables to set before running:
#  - PORT (the port that the app instances are running on)
#  - SERVER_NAMES (the external domain names you expect your app to use)
#  - INTERNAL_DNS_DOMAIN (internal domain name in a private hosted zone for this app's vpc)
# ---------------------------------------------------

# use the "aws_opsworks_app" databag to iterate thru apps
search("aws_opsworks_app").each do |app|

    # find the (1) instance this recipe is being executed on and (2) its relevant layers
    instance = search("aws_opsworks_instance", "self:true").first
    Chef::Log.info("****** Instance '#{instance['instance_id']}' has the public IP '#{instance['public_ip']}' ******")
    layers = search("aws_opsworks_layer").select do |layer|
        instance[:layer_ids].include? layer[:layer_id]
    end

    # assume each instance is only associated to one layer for simplicity
    instance_layer = layers.first
    if instance_layer[:shortname] == app[:shortname]
        Chef::Log.info("****** Instance layer and app shortnames '#{instance_layer[:shortname]}' match! ******")
        Chef::Log.info("****** Deploying app shortname: '#{app[:shortname]}' ******")
    end

    # ----------------------------------------------------------
    # only deploying apps whose shortnames match instance layer!
    # ----------------------------------------------------------
    # -------------------------------------------------------------------------------
    # NOTE: this step requires an NGINX installation on ubuntu!
    # setup NGINX reverse proxy (set to default) for the application PORT specified
    # -------------------------------------------------------------------------------
    if instance_layer[:shortname] == app[:shortname]
        app_env = app[:environment]
        reverse_proxy_target_port = app_env[:PORT]
        server_names = app_env[:SERVER_NAMES].split(',')
        app_internal_domain = app_env[:INTERNAL_DNS_DOMAIN]

        template "/etc/nginx/sites-available/#{app[:shortname]}" do
            source "nginx-reverse-proxy-dns-lb.erb"
            mode "0755"
            owner "root"
            group "root"
            variables(server_names: server_names,
                      app_internal_domain: app_internal_domain,
                      reverse_proxy_target_port: reverse_proxy_target_port)
        end

        file '/etc/nginx/sites-enabled/default' do
            action :delete
        end

        link "/etc/nginx/sites-enabled/#{app[:shortname]}" do
            to "/etc/nginx/sites-available/#{app[:shortname]}"
            link_type :symbolic
            mode "0755"
            owner "root"
            group "root"
        end

        service "nginx" do
            action [ :stop ,:start ]
        end
    end

end
