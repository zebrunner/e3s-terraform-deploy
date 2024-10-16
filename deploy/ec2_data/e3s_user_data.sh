#!/bin/bash

user="ubuntu"
e3s_path="/home/$user/tools/e3s"

replace() {
  param=$1
  value=$2
  file=$3

  sed -i -e "s^$param.*^$value^" "$file"
}

sudo apt-get update && sudo apt-get upgrade

# install jq
sudo apt-get -y install jq unzip

# insall aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Add Docker's official GPG key:
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker "$user"
# Grant admin rights
sudo usermod -aG sudo "$user"

git config --system --add safe.directory '*'

mkdir -p "$e3s_path"
git clone https://github.com/zebrunner/e3s.git "$e3s_path"

if [ -n "${agent_key}" ]; then
  echo "${agent_key}" > "$e3s_path"/${agent_key_name}.pem
  chmod 400 "$e3s_path"/${agent_key_name}.pem
fi

cd "$e3s_path"
case ${remote_data} in 
  (true) 
    git checkout "main"

    # data.env
    replace "POSTGRES_PASSWORD" "POSTGRES_PASSWORD=${db_pass}" "./properties/data.env"
    replace "DATABASE" "DATABASE=postgres://${db_username}:${db_pass}@${db_dns}/${db_name}" "./properties/data.env"
    replace "ELASTIC_CACHE" "ELASTIC_CACHE=${cache_address}:${cache_port}" "./properties/data.env"
    replace "CACHE_REMOTE" "CACHE_REMOTE=true" "./properties/data.env"
  ;;
  (false)
    git checkout "main-local"
  ;;
  (*) 
    echo "remote_data is not a bool value"
  ;;
esac

case ${nat} in 
  (true)
    replace "SERVICE_STARTUP_TIMEOUT" "SERVICE_STARTUP_TIMEOUT=5m45s" "./properties/router.env"
  ;;
  (false)
    replace "SERVICE_STARTUP_TIMEOUT" "SERVICE_STARTUP_TIMEOUT=10m" "./properties/router.env"
  ;;
  (*) 
    echo "nat is not a bool value"
  ;;
esac

# config.env
replace "AWS_REGION" "AWS_REGION=${region}" "./properties/config.env"
replace "AWS_CLUSTER" "AWS_CLUSTER=${cluster_name}" "./properties/config.env"
replace "AWS_TASK_ROLE" "AWS_TASK_ROLE=${task_role}" "./properties/config.env"
replace "AWS_LOGS_GROUP" "AWS_LOGS_GROUP=${log_group}" "./properties/config.env"
replace "S3_BUCKET" "S3_BUCKET=${bucket_name}" "./properties/config.env"
replace "S3_REGION" "S3_REGION=${bucket_region}" "./properties/config.env"
replace "ZEBRUNNER_HOST" "ZEBRUNNER_HOST=${zbr_host}" "./properties/config.env"
replace "ZEBRUNNER_INTEGRATION_USER" "ZEBRUNNER_INTEGRATION_USER=${zbr_user}" "./properties/config.env"
replace "ZEBRUNNER_INTEGRATION_PASSWORD" "ZEBRUNNER_INTEGRATION_PASSWORD=${zbr_pass}" "./properties/config.env"
replace "ZEBRUNNER_ENV" "ZEBRUNNER_ENV=${env}" "./properties/config.env"

# router.env
replace "AWS_LINUX_CAPACITY_PROVIDER" "AWS_LINUX_CAPACITY_PROVIDER=${linux_capacityprovider}" "./properties/router.env"
replace "AWS_WIN_CAPACITY_PROVIDER" "AWS_WIN_CAPACITY_PROVIDER=${windows_capacityprovider}" "./properties/router.env"
replace "AWS_TARGET_GROUP" "AWS_TARGET_GROUP=${target_group}" "./properties/router.env"

# scaler.env

# task-definitions.env

# datasources.yml
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && e3s_private_ip=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4`
replace "http://{e3s_private_ip}:9090" "http://${e3s_private_ip}:9090" "./monitoring/grafana/provisioning/datasources/datasources.yml"
replace "http://{e3s_private_ip}:9093" "http://${e3s_private_ip}:9093" "./monitoring/grafana/provisioning/datasources/datasources.yml"

# prometheus.yml
replace "e3s-{env}-linux-asg" "${linux_asg}" "./monitoring/prometheus/prometheus.yml"
replace "e3s-{env}-windows-asg" "${windows_asg}" "./monitoring/prometheus/prometheus.yml"

# start server
./zebrunner.sh start

sudo chown -R "$user" "$e3s_path"