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
        Chef::Log.info("****** Deploying app shortname: '#{app[:shortname]}' url: '#{app[:app_source][:url]} ******")
    end

    # ----------------------------------------------------------
    # only deploying apps whose shortnames match instance layer!
    # ----------------------------------------------------------

    # build app url we'll use to read & clone the repo
    app_env = app[:environment]
    app_url = app[:app_source][:url].sub! "://" , "://#{app_env[:GITLAB_DEPLOY_USER]}:#{app_env[:GITLAB_DEPLOY_PASSWORD]}@"

    bash "pm2_deploy_app" do
        only_if do
            instance_layer[:shortname] == app[:shortname]
        end
        user "ubuntu"
        group "ubuntu"
        cwd "/home/ubuntu"
        environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu', 'PORT' => app_env[:PORT] })
        code <<-EOH
            # clean the app repo if one exists already
            rm -rf #{app[:shortname]}
            # clone the repo using deploy tokens
            git clone #{app_url} #{app[:shortname]}
    
            # try to set up the PATH variable for nvm stuff
            export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
            echo $PATH
    
            # install all npm dependencies (from package.json)
            cd #{app[:shortname]} && npm i
            # deploy using pm2 (ensure no other apps running first and deploy script exists)
            pm2 kill
            npm run deploy
        EOH
    end

end
