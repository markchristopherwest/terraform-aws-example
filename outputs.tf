output "endpoints" {
  value = <<EOF

  NOTE: While Terraform's work is done, these instances need time to complete
        their own installation and configuration. Progress is reported within
        the log file `/var/log/user-data.log` and reports 'Complete' when
        the instance is ready.  SSM into the instance to be leader & run::

        journalctl -u vault
        vault operator init
        vault login
        vault operator list-peers

  AWS AMI: ${data.aws_ami.demo.id}

  Vault Cluster Auto Scaling Group Name     = ${module.vault_cluster.asg_name}
  Vault Cluster Launch Config Name          = ${module.vault_cluster.launch_config_name}
  Vault Cluster Auto Join Locator Tags      = ${module.vault_cluster.cluster_tag_key}:${module.vault_cluster.cluster_tag_value}
  Vautl Cluster Raft Instance Count         = ${module.vault_cluster.cluster_size}

  Verify PKI Chain:

  openssl verify -CAfile ${module.private_tls_cert.ca_public_key_file_path} ${module.private_tls_cert.public_key_file_path}

EOF
}
