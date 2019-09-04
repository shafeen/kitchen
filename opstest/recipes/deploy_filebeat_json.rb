# ---------------------------------------------------
#  Environment variables to set before running:
#  - USER_HOME_DIR
#  - APP_LOG_DIR - the directory containing the application logs
#  - ELASTICSEARCH_SERVER_ADDR - ip address or dns name for the elasticsearch server
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

        user_name = "ubuntu"
        user_home_dir = app_env[:USER_HOME_DIR]

        # download filebeat
        filebeat_url = "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.2.0-linux-x86_64.tar.gz"
        filebeat_download_file = "filebeat.tar.gz"
        filebeat_unzipped_folder = "filebeat-7.2.0-linux-x86_64"
        filebeat_renamed_folder = "filebeat"
        bash "download_filebeat" do
            user user_name
            cwd user_home_dir
            environment ({'HOME' => user_home_dir, 'USER' => user_name})
            code <<-EOH
                # download/rename the filebeat unzipped folder if it doesn't exist yet
                if [ ! -d '#{filebeat_renamed_folder}' ] 
                then
                    wget #{filebeat_url} -O #{filebeat_download_file}
                    tar -xzvf #{filebeat_download_file} && rm #{filebeat_download_file}
                    mv #{filebeat_unzipped_folder} #{filebeat_renamed_folder}
                fi
            EOH
        end

        # setup filebeat.yml (with root ownership) to send the appropriate log files to elasticsearch
        filebeat_folder_path = "#{user_home_dir}/#{filebeat_renamed_folder}"
        filebeat_config_filename = "filebeat.yml"
        template "#{filebeat_folder_path}/#{filebeat_config_filename}" do
            source "filebeat-7-2-0.yml.erb"
            mode "0755"
            owner "root"
            group user_name
            variables(app_log_dir: app_env[:APP_LOG_DIR],
                      elasticsearch_server_addr: app_env[:ELASTICSEARCH_SERVER_ADDR])
            action :create
        end

        # setup pm2 filebeat's ecosystem file for pm2 (we must run it as root)
        pm2_ecosystem_filename = "ecosystem.config.js"
        template "#{filebeat_folder_path}/#{pm2_ecosystem_filename}" do
            source "filebeat-ecosystem.config.js.erb"
            mode "0755"
            owner "root"
            group "root"
            variables(pm2_ecosystem_filename: pm2_ecosystem_filename)
            action :create
        end

        # ---------------------------------
        # launch filebeat (if not running)
        # ---------------------------------
        bash "start_filebeat" do
            user "root"
            group "root"
            cwd user_home_dir
            environment ({'FILEBEAT_FOLDER' => filebeat_folder_path, 'USER' => 'root'})
            code <<-EOH
                # try to set up the PATH variable for nvm stuff
                export PATH=#{user_home_dir}/.nvm/versions/node/v10.15.3/bin:$PATH
                echo $PATH
                cd $FILEBEAT_FOLDER
                # only start filebeat with pm2 if it isn't running already
                [[ `pm2 pid filebeat` != '' ]] && echo 'filebeat already running' || pm2 start
            EOH
        end
    end
end