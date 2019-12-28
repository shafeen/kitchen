# -------------------------------------------------------------
#  Required Environment variables to set before running
#  ====================================================
#  - GITLAB_DEPLOY_USER
#  - GITLAB_DEPLOY_PASSWORD
#  - PORT
#
#  package.json requirements
#  =========================
#  The app MUST have an npm script defined called "deploy" for
#  this recipe to function correctly.
#
#  Dotenv support for injecting env variables specific to the app
#  ==============================================================
#  Optional environment variables to pass into the app's '.env' file
#  should be prefixed with 'DOTENV_<name>'; these will get passed into
#  the created '.env' file in the  project root directory with the
#  'DOTENV_' prefix stripped out.
#  Example:
#  The env variable 'DOTENV_APPENV_1' will be renamed to 'APPENV_1'
#  and injected into the project's '.env' file.
#
# -------------------------------------------------------------

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
        if app[:app_source][:url]
            Chef::Log.info("****** Deploying app shortname: '#{app[:shortname]}' url: '#{app[:app_source][:url]} ******")
        end

        USER = "ubuntu"
        USER_HOME = "/home/#{USER}"

        # ----------------------------------------------------------
        # only deploying apps whose shortnames match instance layer!
        # ----------------------------------------------------------

        # build app url we'll use to read & clone the repo
        app_env = app[:environment]
        app_url = app[:app_source][:url].sub! "://" , "://#{app_env[:GITLAB_DEPLOY_USER]}:#{app_env[:GITLAB_DEPLOY_PASSWORD]}@"
        app_branch = (app[:app_source][:revision] && app[:app_source][:revision] != "null")? app[:app_source][:revision] : "master"

        bash "pm2_download_app" do
            user USER
            group USER
            cwd USER_HOME
            environment ({'HOME' => USER_HOME, 'USER' => USER, 'PORT' => app_env[:PORT]})
            code <<-EOH
                # clean the app repo if one exists already
                rm -rf #{app[:shortname]}
                # clone the repo using deploy tokens
                git clone #{app_url} #{app[:shortname]} --single-branch --branch #{app_branch}
            EOH
        end

        # ------------------------------------------------------
        # dotenv support -- must be set up before the app starts
        # ------------------------------------------------------
        DOTENV_PREFIX = 'DOTENV_'
        dotenv_entries = app_env.select { |key, value| key[0..DOTENV_PREFIX.length-1] == DOTENV_PREFIX }
        dotenv_file_entries = dotenv_entries.map { |key, value|  [key[DOTENV_PREFIX.length..-1], value] }.to_h
        app_folder_path = "#{USER_HOME}/#{app[:shortname]}"
        dotenv_file_path = "#{app_folder_path}/.env"
        dotenv_template = "dotenv.erb"
        template dotenv_file_path do
            only_if "test -d #{app_folder_path}"
            source dotenv_template
            mode "0644"
            owner USER
            group USER
            variables(dotenv_file_entries: dotenv_file_entries)
        end

        bash "pm2_deploy_app" do
            user USER
            group USER
            cwd USER_HOME
            environment ({'HOME' => USER_HOME, 'USER' => USER, 'PORT' => app_env[:PORT]})
            code <<-EOH
                # try to set up the PATH variable for nvm stuff
                export PATH=$HOME/.nvm/versions/node/v10.15.3/bin:$PATH
                echo $PATH
        
                # install all npm dependencies (from package.json)
                cd #{app[:shortname]} && npm i
                # deploy using pm2 (ensure no other apps running first and deploy script exists)
                pm2 kill
                npm run deploy
            EOH
        end

    end

end
