bash "install_node10_nvm" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        curl -o- https://raw.g  ithubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
        source ~/.bashrc
        nvm install 10.15.3
    EOH
end