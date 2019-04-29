app = search("aws_opsworks_app").first

Chef::Log.info("****** app shortname: '#{app[:shortname]}' url: '#{app[:app_source][:url]} ******")

# build the app url we'll sue to read & clone the repo
app_env = app[:environment]
app_url = app[:app_source][:url].sub! "://" , "://#{app_env[:GITLAB_DEPLOY_USER]}:#{app_env[:GITLAB_DEPLOY_PASSWORD]}@"

# find the (1) instance this recipe is being executed on and (2) its relevant layers
instance = search("aws_opsworks_instance", "self:true").first
Chef::Log.info("****** Instance '#{instance['instance_id']}' has the public IP '#{instance['public_ip']}' ******")
layers = search("aws_opsworks_layer").select do |layer|
    instance[:layer_ids].include? layer[:layer_id]
end

# assume each instance is associated to only one layer
instance_layer = layers.first

# only deploy apps whose shortnames match instance layer
bash "clone_app_repo" do
    only_if do
        instance_layer[:shortname] == app[:shortname]
    end
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # first clean the app repo if one exists already
        rm -rf #{app[:shortname]}
        # clone the repo using deploy tokens
        git clone #{app_url} #{app[:shortname]}
    EOH
end

bash "pm2_deploy_app" do
    only_if do
        layers.first[:shortname] == app[:shortname]
    end
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu/#{app[:shortname]}"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # try to set up the PATH variable for nvm stuff
        export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
        echo $PATH
        # install all npm dependencies (from package.json)
        npm i
        # deploy using pm2
        pm2 start app.js
    EOH
end

# do more here later as part of the deploy task