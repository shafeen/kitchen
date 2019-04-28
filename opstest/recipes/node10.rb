bash "install_node10_nvm" do
    user "ubuntu"
    cwd "$HOME"
    code <<-EOH
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
        nvm install 10.15.3
    EOH
end