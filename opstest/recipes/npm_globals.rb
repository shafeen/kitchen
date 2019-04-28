bash "install_npm_globals" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # ------ make sure nvm was installed first
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
        # ------ end loading nvm
        npm i -g gulp@3.9.1 pm2
    EOH
end