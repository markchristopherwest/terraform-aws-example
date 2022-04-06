#!/bin/bash
# This script is used to configure and run Vault on an AWS server.

set -e

exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

logger(){
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running vault-run..."

readonly VAULT_CONFIG_FILE="default.hcl"
readonly VAULT_PID_FILE="vault-pid"
readonly VAULT_TOKEN_FILE="vault-token"
readonly SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"

readonly DEFAULT_AGENT_VAULT_ADDRESS="vault.service.consul"
readonly DEFAULT_AGENT_AUTH_MOUNT_PATH="auth/aws"

readonly DEFAULT_PORT=8200
readonly DEFAULT_LOG_LEVEL="info"

readonly DEFAULT_CONSUL_AGENT_SERVICE_REGISTRATION_ADDRESS="localhost:8500"

readonly EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"

readonly SCRIPT_NAME="$(basename "$0")"



id_instance="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

ip_inside="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
ip_outside="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

address_api="http://$ip_inside:8200"
address_cluster="http://$ip_inside:8201"

logger "Preparing Vault license file in ${key_path_vault}"
sudo echo "${key_app_vault}" > ${key_path_vault}


logger "Backing up default Vault config file in /etc/vault.d/vault.hcl"
sudo cp /etc/vault.d/vault.hcl /etc/vault.d/vault.hcl.original

logger "Preparing default Vault config file in $config_path"
sudo touch /opt/vault/config/vault.hcl

sudo tee /opt/vault/config/vault.hcl <<EOF
# Full configuration options can be found at https://www.vaultproject.io/docs/configuration

ui = true

api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://$ip_inside:8201"

#mlock = true
#disable_mlock = true

storage "raft" {
  path = "${path_raft_storage}"
  node_id = "$id_instance"

  retry_join {
    leader_ca_cert_file = "${path_cert_ca}"
    leader_tls_servername = "${tls_server_common_name}"
    auto_join = "provider=aws addr_type=private_v4 aws_region=${aws_region} tag_key=${tag_key} tag_value=${tag_value}"
  }
}

#storage "consul" {
#  address = "127.0.0.1:8500"
#  path    = "vault"
#}

# HTTP listener
#listener "tcp" {
#  address = "127.0.0.1:8200"
#  tls_disable = 1
#}

# HTTPS listener
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_client_ca_file = "${path_cert_ca}"
  tls_cert_file = "${path_cert_server}"
  tls_key_file  = "${path_key_server}"
}

# Enterprise license_path
# This will be required for enterprise as of v1.8
license_path = "/opt/vault/config/vault.hclic"

# Example AWS KMS auto unseal
seal "awskms" {
  region = "us-east-1"
  kms_key_id = "${key_aws_kms}"
}

# Example HSM auto unseal
#seal "pkcs11" {
#  lib            = "/usr/vault/lib/libCryptoki2_64.so"
#  slot           = "0"
#  pin            = "AAAA-BBBB-CCCC-DDDD"
#  key_label      = "vault-hsm-key"
#  hmac_key_label = "vault-hsm-hmac-key"
#}


EOF


logger "Overwriting default Vault config file with generated config file..."
sudo cp /opt/vault/config/vault.hcl /etc/vault.d/vault.hcl

logger "Preparing default Vault config file in /etc/environment"

sudo tee -a /etc/environment <<EOF
VAULT_API_ADDR=http://127.0.0.1:8200
VAULT_CLUSTER_ADDR=http://127.0.0.1:8201
VAULT_SKIP_VERIFY=true


EOF




logger "Reloading systemd config and starting Vault"
sudo systemctl daemon-reload
sudo systemctl enable vault.service
sudo systemctl restart vault.service
sleep 60

# Based on: http://unix.stackexchange.com/a/7732/215969
# function get_owner_of_path {
#   local -r path="$1"
#   ls -ld "$path" | awk '{print $3}'
# }

