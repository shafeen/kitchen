# NOTE: you must ensure nodejs >= 10 and pm2 is installed before running the recipe
#
# https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html
#
elasticsearch_url = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.2.0-linux-x86_64.tar.gz"
elasticsearch_download_file = "elasticsearch.tar.gz"
elasticsearch_unzipped_folder = "elasticsearch-7.2.0"
elasticsearch_renamed_folder = "elasticsearch"

kibana_url = "https://artifacts.elastic.co/downloads/kibana/kibana-7.2.0-linux-x86_64.tar.gz"
kibana_download_file = "kibana.tar.gz"
kibana_unzipped_folder = "kibana-7.2.0-linux-x86_64"
kibana_renamed_folder = "kibana"

bash "download_elasticsearch_kibana" do
    user "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        wget #{elasticsearch_url} -O #{elasticsearch_download_file}
        tar -xzvf #{elasticsearch_download_file} && rm #{elasticsearch_download_file}
        mv #{elasticsearch_unzipped_folder} #{elasticsearch_renamed_folder}
        wget #{kibana_url} -O #{kibana_download_file}
        tar -xzvf #{kibana_download_file} && rm #{kibana_download_file}
        mv #{kibana_unzipped_folder} #{kibana_renamed_folder}
    EOH
end

pm2_ecosystem_filename = "ecosystem.config.js"

# --------------------
# setup elasticsearch
# --------------------
elasticsearch_config_filename = "elasticsearch.yml"
template "/home/ubuntu/#{elasticsearch_renamed_folder}/#{pm2_ecosystem_filename}" do
    source "elasticsearch-ecosystem.config.js.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(elasticsearch_config_filename: elasticsearch_config_filename,
              pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end
template "/home/ubuntu/#{elasticsearch_renamed_folder}/config/#{elasticsearch_config_filename}" do
    source "elasticsearch-7-2-0.yml.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

# -----------------
# setup grafana
# TODO: setup custom.ini (configuration file)
# -----------------
kibana_config_filename = "kibana.yml"
template "/home/ubuntu/#{kibana_renamed_folder}/#{pm2_ecosystem_filename}" do
    source "kibana-ecosystem.config.js.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(pm2_ecosystem_filename: pm2_ecosystem_filename)
    action :create
end

# TODO: need to specify a set of dns addresses in the yml file in the future for elasticsearch hosts
elasticsearch_host = "localhost"
template "/home/ubuntu/#{kibana_renamed_folder}/config/#{kibana_config_filename}" do
    source "kibana-7-2-0.yml.erb"
    mode "0755"
    owner "ubuntu"
    group "ubuntu"
    variables(elasticsearch_host: elasticsearch_host)
    action :create
end

# ------------------------------
# launch prometheus & grafana
# ------------------------------
bash "start_elasticsearch_kibana" do
    user "ubuntu"
    group "ubuntu"
    cwd "/home/ubuntu"
    environment ({'HOME' => '/home/ubuntu', 'USER' => 'ubuntu'})
    code <<-EOH
        # try to set up the PATH variable for nvm stuff
        export PATH=/home/ubuntu/.nvm/versions/node/v10.15.3/bin:$PATH
        echo $PATH

        cd $HOME/#{elasticsearch_renamed_folder} && pm2 start
        cd $HOME/#{kibana_renamed_folder} && pm2 start
    EOH
end
