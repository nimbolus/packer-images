# Packer Images

```sh
export PKR_VAR_flavor_id="<flavor-id>"
export PKR_VAR_networks='["<network-id>"]'
packer init
packer build -only "ansible.openstack.ubuntu-22_04" images/ansible
```

## GitLab CI

Checkout `example.gitlab-ci.yml` for an example pipeline definition.
