prometheus_url = "https://github.com/prometheus/prometheus/releases/download/v2.9.2/prometheus-2.9.2.linux-amd64.tar.gz"
prometheus_download_file = "prometheus.tar.gz"
prometheus_unzipped_folder = "prometheus-2.9.2.linux-amd64"
prometheus_renamed_folder = "prometheus"

grafana_url = "https://dl.grafana.com/oss/release/grafana-6.1.6.linux-amd64.tar.gz"
grafana_download_file = "grafana-6.1.6.linux-amd64.tar.gz"
grafana_unzipped_folder = "grafana-6.1.6"
grafana_renamed_folder = "grafana"

bash "install_prometheus_grafana" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        wget #{prometheus_url} -O #{prometheus_download_file}
        tar -xvzf #{prometheus_download_file} && rm #{prometheus_download_file}
        mv #{prometheus_unzipped_folder} #{prometheus_renamed_folder}
        wget #{grafana_url} -O #{grafana_download_file}
        tar -xvzf #{grafana_download_file} && rm #{grafana_download_file}
        mv #{grafana_unzipped_folder} #{grafana_renamed_folder}
    EOH
end

pm2_ecosystem_filename = "ecosystem.config.js"

# -----------------
# setup prometheus
# -----------------
prometheus_config_filename = "prometheus.yml"
template "/home/ubuntu/#{prometheus_renamed_folder}/#{pm2_ecosystem_filename}" do
    source "prometheus-ecosystem.config.js.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(prometheus_config_filename: prometheus_config_filename,
              pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end
template "/home/ubuntu/#{prometheus_renamed_folder}/#{prometheus_config_filename}" do
    source "prometheus.yml.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(prometheus_config_filename: prometheus_config_filename,
              pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

# -----------------
# setup grafana
# TODO: setup custom.ini (configuration file)
# -----------------
template "/home/ubuntu/#{grafana_renamed_folder}/#{pm2_ecosystem_filename}" do
    source "grafana-ecosystem.config.js.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

# ------------------------------
# launch prometheus & grafana
# ------------------------------
bash "start_prometheus_grafana" do
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # try to set up the PATH variable for nvm stuff
        export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
        echo $PATH

        cd $HOME/#{prometheus_unzipped_folder} && pm2 start
        cd $HOME/#{grafana_unzipped_folder} && pm2 start
    EOH
end
