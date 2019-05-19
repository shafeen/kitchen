prometheus_url = "https://github.com/prometheus/prometheus/releases/download/v2.9.2/prometheus-2.9.2.linux-amd64.tar.gz"
prometheus_download_file = "prometheus.tar.gz"
expected_unzipped_folder = "prometheus-2.9.2.linux-amd64"

bash "install_prometheus" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        wget #{prometheus_url} -O #{prometheus_download_file}
        tar -xvzf #{prometheus_download_file} && rm #{prometheus_download_file}
    EOH
end

pm2_ecosystem_filename = "ecosystem.config.js"
prometheus_config_filename = "prometheus.yml"

template "/home/ubuntu/#{expected_unzipped_folder}/#{pm2_ecosystem_filename}" do
    source "prometheus-ecosystem.config.js.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(prometheus_config_filename: prometheus_config_filename,
              pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

template "/home/ubuntu/#{expected_unzipped_folder}/#{prometheus_config_filename}" do
    source "prometheus.yml.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(prometheus_config_filename: prometheus_config_filename,
              pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

bash "start_prometheus" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        cd #{expected_unzipped_folder}
        pm2 start
    EOH
end
