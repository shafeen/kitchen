package "nginx" do
    action :install
    version "1.14.*"
end

# ensure the service is started (change this later)
service "nginx" do
    action [ :enable, :start ]
end
