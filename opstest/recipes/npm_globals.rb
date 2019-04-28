bash "install_npm_globals" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        npm i -g gulp@3.9.1 pm2
    EOH
end