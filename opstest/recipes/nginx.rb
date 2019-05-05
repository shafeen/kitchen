package "nginx" do
    action :install
    version "1.14.*"
end

# ensure the service is stopped after installation
# deploy steps should take care of enabling this as needed
service "nginx" do
    action [ :enable, :stop ]
end
