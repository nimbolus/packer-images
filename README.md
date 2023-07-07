# Packer Images

```sh
packer init
packer build -only "ansible.openstack.ubuntu-22_04" images/ansible
```

## GitLab CI

Checkout `example.gitlab-ci.yml` for an example pipeline definition.
