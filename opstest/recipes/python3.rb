# install virtualenv and pip3
["python3-venv", "python3-pip"].each do |package_name|
    package package_name do
        action :install
    end
end

# install pipenv as a "user installation"
bash "install pip3 pipenv" do
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        pip3 install --user pipenv
    EOH
end

# install other required pip3 modules
["boto3"].each do |pip3_package_name|
    bash "install pip3 package '#{pip3_package_name}'" do
        user "ubuntu"
        group "ubuntu"
        cwd "/home/ubuntu"
        environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
        code <<-EOH
            pip3 install #{pip3_package_name}
        EOH
    end
end