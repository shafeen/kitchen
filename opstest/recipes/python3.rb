["python3-pip"].each do |package_name|
    package package_name do
        action :install
    end
end