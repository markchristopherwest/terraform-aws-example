# Hashistack

## Getting Started

Ready?

Meeting Playlist: "Ooh La La" by Goldfrapp

https://www.youtube.com/watch?v=uco-2V4ytYQ



### Switch Me On

Run Terraform (which calls Packer)

```sh
terraform init
terraform plan
terraform apply
#terraform destroy
```


### Turn Me Up

Run Vault (which Auto Joins with KMS)

```sh
# ssm to your instance
vault operator init
vault login
vault operator raft list-peers
```

### Made For Love

Enable secrets backends (KV, PKI, etc.)

```sh
# ssm to your instance
vault secrets enable -path=secret kv-v2
vault kv get secret/hello
vault kv put secret/hello foo=world

# You can even write multiple pieces of data.
vault kv put secret/hello foo=world excited=yes

# Getting a Secret
vault kv get secret/hello

# Deleting a Secret
vault kv delete secret/hello

# PKI Secrets Engine
vault secrets enable pki
vault secrets enable pki pki_int
vault secrets tune -max-lease-ttl=8760h pki
vault write pki/root/generate/internal \
    common_name=my-website.com \
    ttl=8760h
vault write pki/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"
vault write pki/roles/example-dot-com \
    allowed_domains=my-website.com \
    allow_subdomains=true \
    max_ttl=72h
vault write pki/issue/example-dot-com \
    common_name=www.my-website.com
```


### Modules

No modules were harmed in the creation of this demo.

https://www.youtube.com/watch?v=OczRpuGKTfY

Kings Of Convenience - "I'd Rather Dance With You"

https://www.youtube.com/watch?v=SDTZ7iX4vTQ

Foster The People - "Pumped Up Kicks (Official Video)"

### Other Concerns

Got that Apple Mac Silicon w/ go installed?

```sh
git clone https://github.com/hashicorp/terraform-provider-template
cd terraform-provider-template
make
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/hashicorp/template/2.2.0/darwin_arm64/ 
cp ~/go/bin/terraform-provider-template ~/.terraform.d/plugins/registry.terraform.io/hashicorp/template/2.2.0/darwin_arm64/terraform-provider-template_v2.2.0_x5
rm .terraform.lock.hcl
terraform init
```

