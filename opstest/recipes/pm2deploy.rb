node[:deploy].each do |application, deploy|

    bash "clone_app_repo" do
        user "ubuntu"
        group "ubuntu"
        cwd "/home/ubuntu"
        environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
        code <<-EOH
            # add git deploy key to agent
            echo "#{deploy[:scm][:ssh_key]}" | tr -d '\r' | ssh-add - > /dev/null
            # clone the repo
            git clone #{deploy[:scm][:repository]} #{application}
        EOH
    end

    # do more here later as part of the deploy task
end