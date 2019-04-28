include_recipe 'deploy'


node[:deploy].each do |application, deploy|
    opsworks_deploy_dir do
        user "ubuntu"
        group "ubuntu"
        path deploy[:deploy_to]
    end

    opsworks_deploy do
        user "ubuntu"
        deploy_data deploy
        app application
    end

    # do more here later
end