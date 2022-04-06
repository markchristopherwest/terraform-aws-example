provider "aws" {
  region = var.aws_region
}

resource "random_pet" "env" {
  length    = 2
  separator = "_"
}

data "aws_ami" "demo" {
  depends_on  = [null_resource.packer_build]
  owners      = [var.ami_owner]
  most_recent = true
  filter {
    name   = "name"
    values = ["vault-ubuntu20*"]
  }

}
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# data "aws_subnet_ids" "all" {
#   vpc_id = module.vault_demo_vpc.vpc_id

# }

# locals {
#   all_subnet_ids = tolist(data.aws_subnet_ids.all.ids)
# }


# Step 1 : Generate PKI for Vault
module "private_tls_cert" {
  source                  = "github.com/hashicorp/terraform-aws-vault//modules/private-tls-cert"
  ca_public_key_file_path = "${path.module}/pki/ca.crt.pem"
  public_key_file_path    = "${path.module}/pki/vault.crt.pem"
  private_key_file_path   = "${path.module}/pki/vault.crt.key"
  owner                   = "mark"
  organization_name       = "Beyond Corp, inc."
  ca_common_name          = var.ca_common_name
  common_name             = var.common_name
  dns_names = [
    "localhost",
    "*.ec2.internal",
    "*.amazonaws.com",
    var.common_name
  ]
  ip_addresses          = ["127.0.0.1"]
  validity_period_hours = 87600

}

# https://registry.terraform.io/modules/terraform-aws-modules/key-pair/aws/latest?tab=outputs
// create Private Key Material for use as SSH Key
resource "tls_private_key" "bar" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

// register Public Key part of SSH Key with EC2 Console
resource "aws_key_pair" "bar" {
  key_name   = random_pet.env.id
  public_key = tls_private_key.bar.public_key_openssh

  tags = {
    Name = random_pet.env.id
  }
}

// render Private Key part of SSH Key as a local file
resource "local_file" "bar" {
  content  = tls_private_key.bar.private_key_pem
  filename = "${path.module}/pki/${random_pet.env.id}.pem"

  // set correct permissions on Private Key file
  file_permission = "0400"
}

# Step 2 : Build AMI for Consul & Vault from Reference Architecture
resource "null_resource" "packer_build" {
  provisioner "local-exec" {
    command = "packer build ${path.root}/config/ami.json"

  }

}


# Step 3 : Instrument Use Case for Vault IAM Auth from Reference Architecture

module "vault_cluster" {
  # Use version v0.0.1 of the vault-cluster module
  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster?ref=v0.17.0"

  # Specify the ID of the Vault AMI. You should build this using the scripts in the install-vault module.
  ami_id = data.aws_ami.demo.id

  # Configure and start Vault during boot.
  user_data = templatefile("scripts/run-vault.sh", {
    api_addr                                          = "127.0.0.1"
    path_app                                          = "/opt/vault"
    path_cert_ca                                      = "/opt/vault/tls/ca.crt.pem",
    path_cert_server                                  = "/opt/vault/tls/vault.crt.pem",
    path_key_server                                   = "/opt/vault/tls/vault.key.pem",
    path_raft_storage                                 = "/opt/vault/data"
    aws_region                                        = var.aws_region,
    key_aws_kms                                       = "${aws_kms_key.vault.key_id}",
    key_app_vault                                     = file("${path.root}/config/vault.lic"),
    key_path_vault                                    = "/opt/vault/config/vault.hclic",
    BASH_SOURCE                                       = "/opt/vault/bin/run-vault",
    DEFAULT_CONSUL_AGENT_SERVICE_REGISTRATION_ADDRESS = "",
    timestamp                                         = "",
    level                                             = "",
    message                                           = ""
    name                                              = "vault-enterprise"
    tag_key                                           = "Name"
    tag_value                                         = random_pet.env.id
    tls_ca_common_name                                = var.ca_common_name
    tls_server_common_name                            = var.common_name


  })

  # Add tag to each node in the cluster with value set to var.cluster_name
  cluster_tag_key = "Name"

  # Optionally add extra tags to each node in the cluster
  cluster_extra_tags = [
    {
      key                 = "Environment"
      value               = "Dev"
      propagate_at_launch = true
    },
    {
      key                 = "Department"
      value               = "Ops"
      propagate_at_launch = true
    }
  ]

  # ... See variables.tf for the other parameters you must define for the vault-cluster module
  cluster_name                         = random_pet.env.id
  instance_type                        = var.instance_type
  vpc_id                               = module.vault_demo_vpc.vpc_id
  allowed_inbound_cidr_blocks          = ["0.0.0.0/0"]
  allowed_inbound_security_group_ids   = [aws_security_group.testing.id]
  allowed_inbound_security_group_count = 0
  cluster_size                         = 3
  enable_auto_unseal                   = true
  auto_unseal_kms_key_arn              = aws_kms_key.vault.arn
  subnet_ids                           = module.vault_demo_vpc.private_subnets
  # availability_zones = 
  ssh_key_name                   = aws_key_pair.bar.key_name
  allowed_ssh_cidr_blocks        = ["0.0.0.0/0"]
  allowed_ssh_security_group_ids = [aws_security_group.testing.id]
  # associate_public_ip_address    = false

}

module "vault_elb" {
  # Use version v0.0.1 of the vault-elb module
  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-elb?ref=v0.17.0"

  vault_asg_name = module.vault_cluster.asg_name

  # ... See variables.tf for the other parameters you must define for the vault-cluster module
  name                        = "main"
  vpc_id                      = module.vault_demo_vpc.vpc_id
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  subnet_ids                  = module.vault_demo_vpc.private_subnets

}
