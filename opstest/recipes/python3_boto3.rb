# install virtualenv and pip3
["python3-venv", "python3-pip"].each do |package_name|
    package package_name do
        action :install
    end
end

# install the required pip3 modules
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

# install pipenv and any other required "user installation" pip3 modules
["pipenv"].each do |pip3_package_name|
    bash "install pip3 --user package '#{pip3_package_name}'" do
        user "ubuntu"
        group "ubuntu"
        cwd "/home/ubuntu"
        environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
        code <<-EOH
            pip3 install --user #{pip3_package_name}
        EOH
    end
end