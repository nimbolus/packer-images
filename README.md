# Packer Images

```sh
export PKR_VAR_flavor_id="<flavor-id>"
export PKR_VAR_networks='["<network-id>"]'
packer init images/ansible
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

### Podman

All features of the Ansible image plus preinstalled Podman container runtime. Also includes a Ansible playbook for fetching Podman Compose secrets from [HashiCorp Vault Key/Value v2 Engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) by authenticating against the [OpenStack auth plugin](https://github.com/nimbolus/vault-plugin-auth-openstack) and staring Compose stacks. It assumes that Podman Compose files are located at `/opt/<stack-name>/compose.yml` and creates an `.env` file in the same folder with the key/value pairs found in the Vault secret at `<vault_kv_engine_path>/<vault_kv_prefix>/<stack-name>`. The playbook needs to be triggered by running `ansible-playbook /etc/ansible/podman-compose-up.yml` (e.g. with [cloud-init runcmd](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#runcmd)).

| Property                | Description                                     | Example                              |
| ----------------------- | ----------------------------------------------- | ------------------------------------ |
| `vault_addr`            | URL of the Vault server                         | `https://vault.example.com`          |
| `vault_role`            | Role name for the OpenStack auth plugin         | `example-container-host`             |
| `vault_kv_engine_path`  | Mount path of the Vault K/V secrets v2 engine   | `kv` (default: `projects`)           |
| `vault_kv_prefix`       | Path prefix for secrets                         | `project-a/instances/container-host` |
| `podman_compose_stacks` | Names of Compose stacks which should be started | `["traefik","myapp"]`                |
