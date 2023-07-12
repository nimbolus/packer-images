# Packer Images

```sh
export PKR_VAR_flavor_id="<flavor-id>"
export PKR_VAR_networks='["<network-id>"]'
packer init
packer build -only "ansible.openstack.ubuntu-22_04" images/ansible
```

## GitLab CI

Checkout `example.gitlab-ci.yml` for an example pipeline definition.

## Images

### Ansible

Images with Ansible preinstalled and optional certificate-based user authentication for SSH (e.g. with [HashiCorp Vault SSH Engine](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates)).

To enable the certificate user authentication, set the following metadata properties when creating the OpenStack instance:

| Property                    | Description                                     | Example                                                 |
| --------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| `ssh_trusted_user_ca_url`   | URL for downloading the CAs public key          | `https://vault.example.com/v1/ssh/public_key`           |
| `ssh_authorized_principals` | Mapping for certificate entities to local users | `{"debian":["admin"]}` while `debian` is the local user |

These properties can also be set via [OpenStack vendordata](https://docs.openstack.org/nova/latest/user/metadata.html#metadata-vendordata).
Note that `ssh_trusted_user_ca_url` in vendordata gets overridden by the instance metadata while `ssh_authorized_principals` will be merged.

For example to create an OpenStack instance with these properties run:
```sh
openstack server create debian-test \                          
    --image debian-12-ansible --flavor m1.small --network <network-id> \
    --property "ssh_trusted_user_ca_url=https://vault.example.com/v1/ssh/public_key" \
    --property 'ssh_authorized_principals={"debian":["admin"]}'
```
