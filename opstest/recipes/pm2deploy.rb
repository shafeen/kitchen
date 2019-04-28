app = search("aws_opsworks_app").first

Chef::Log.info("********** The app's short name is '#{app[:shortname]}' **********")
Chef::Log.info("********** The app's URL is '#{app[:app_source][:url]}' **********")

#  need to use data bags for chef 12 on OpsWorks
bash "clone_app_repo" do
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # add git deploy key to agent
        echo "#{app[:app_source][:ssh_key]}" | tr -d '\r' | ssh-add - > /dev/null
        # clone the repo
        git clone #{app[:app_source][:url]} #{app[:shortname]}
    EOH
end

# do more here later as part of the deploy task