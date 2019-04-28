app = search("aws_opsworks_app").first

Chef::Log.info("********** The app's short name is '#{app[:shortname]}' **********")
Chef::Log.info("********** The app's URL is '#{app[:app_source][:url]}' **********")

app_env = app[:environment]
app_url = app[:app_source][:url]
app_url = app_url.sub! "://" , "://#{app_env[:GITLAB_DEPLOY_USER]}:#{app_env[:GITLAB_DEPLOY_PASSWORD]}@"

#  need to use data bags for chef 12 on OpsWorks
bash "clone_app_repo" do
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
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu/#{app[:shortname]}"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # try to set up the PATH variable for nvm stuff
        export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
        echo $PATH
        # deploy using pm2
        pm2 start app.js
    EOH
end

# do more here later as part of the deploy task