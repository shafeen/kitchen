# ---------------------------------------------------
#  Environment variables to set before running:
#  - USER_HOME_DIR
#  - APP_LOG_DIR - the directory containing the application logs
#  - LOG_USER
#  - LOG_GROUP
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

        # create the <HOME>/log directory if one doesn't exist
        log_dir = "#{app_env[:USER_HOME_DIR]}/log"
        directory log_dir do
            owner app_env[:LOG_USER]
            group app_env[:LOG_GROUP]
            mode "0644"
            action :create
        end

        # create the directory for housing logrotate.conf (with correct rw root user/group permissions)
        logrotate_conf_dir = "#{log_dir}/logrotate"
        directory logrotate_conf_dir do
            owner "root"
            group "root"
            mode "0644"
            action :create
        end

        # copy the template logrotate.conf file into this directory with root 0644 permissions
        logrotate_conf_path = "#{logrotate_conf_dir}/logrotate.conf"
        num_days_to_rotate = 15
        template logrotate_conf_path do
            source "logrotate.conf.erb"
            mode "0644"
            owner "root"
            group "root"
            variables(app_log_dir: app_env[:APP_LOG_DIR],
                      log_user: app_env[:LOG_USER],
                      log_group: app_env[:LOG_GROUP],
                      num_days_to_rotate: num_days_to_rotate)
        end

        # create the application log directory if it doesn't exist already
        default_app_log_dir = "#{log_dir}/#{app[:shortname]}"
        app_log_dir = if app_env[:APP_LOG_DIR] then app_env[:APP_LOG_DIR] else default_app_log_dir end
        directory app_log_dir do
            owner app_env[:LOG_USER]
            group app_env[:LOG_GROUP]
            mode "0644"
            action :create
        end

        # create a cron job to run once daily at 00:00:00 and run /usr/sbin/logrotate command
        logrotate_executable_path = "/usr/sbin/logrotate"
        cron "schedule daily log rotation" do
            action :create
            minute "0"
            hour "0"
            user "root"
            home app_env[:USER_HOME_DIR]
            command "#{logrotate_executable_path} #{logrotate_conf_path}"
        end
    end
end