build {
  name = "podman"

  source "source.openstack.centos-9-stream" {
    image_name = "${var.image_prefix}centos-9-stream-podman"
  }

  # wait for cloud-init
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"
    ]
  }

  # upgrade and install base packages and podman
  provisioner "shell" {
    only = [
      "openstack.centos-9-stream",
    ]
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y qemu-guest-agent git ansible-core podman nfs-utils",
      "sudo mkdir -p /usr/local/libexec/docker/cli-plugins",
      "sudo curl -Lso /usr/local/libexec/docker/cli-plugins/docker-compose https://github.com/docker/compose/releases/download/v2.29.1/docker-compose-linux-x86_64",
      "sudo chmod 755 /usr/local/libexec/docker/cli-plugins/docker-compose",
    ]
  }

  # enable unattended upgrades
  provisioner "shell" {
    only = [
      "openstack.centos-9-stream",
    ]
    inline = [
      "sudo dnf install -y dnf-automatic",
      "sudo systemctl enable dnf-automatic-install.timer",
    ]
  }

  # add ssh-ca-auth service
  provisioner "file" {
    source      = "images/ansible/ssh-ca-auth"
    destination = "/tmp/ssh-ca-auth"
  }
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/ansible",
      "sudo mv /tmp/ssh-ca-auth/playbook.yml /etc/ansible/ssh-ca-auth.yml",
      "sudo mv /tmp/ssh-ca-auth/ssh-ca-auth.service /etc/systemd/system/ssh-ca-auth.service",
      "sudo /usr/bin/ansible-galaxy install -r /tmp/ssh-ca-auth/requirements.yml",
      "sudo rm -r /tmp/ssh-ca-auth",
      "sudo bash -c 'if command -v restorecon &> /dev/null; then restorecon /etc/systemd/system/ssh-ca-auth.service; fi'",
      "sudo systemctl enable ssh-ca-auth",
    ]
  }

  # add podman-compose-up playbook
  provisioner "file" {
    source      = "images/podman/podman-compose-up"
    destination = "/tmp/podman-compose-up"
  }
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/ansible",
      "sudo mv /tmp/podman-compose-up/playbook.yml /etc/ansible/podman-compose-up.yml",
      "sudo /usr/bin/ansible-galaxy install -r /tmp/podman-compose-up/requirements.yml",
      "sudo rm -r /tmp/podman-compose-up",
    ]
  }

  # post script
  provisioner "shell" {
    inline = var.post_script
  }

  # empty resolv.conf - https://git.centos.org/centos/kickstarts/pull-request/12#
  provisioner "shell" {
    only = [
      "openstack.centos-9-stream",
    ]
    inline = [
      "echo | sudo tee /etc/resolv.conf"
    ]
  }

  # cleaning for smaller image
  provisioner "shell" {
    only = [
      "openstack.centos-9-stream",
    ]
    inline = [
      "sudo dnf autoremove -y && dnf clean all && sudo rm -rf /var/cache/yum",
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo rm -rf /tmp/*",
      "sudo find /var/log/ -name *.log -exec rm -f {} \\;",
      <<-EOT
        sudo bash -c 'if [[ "$(df -T /)" != *"btrfs"* ]]; then
          dd if=/dev/zero of=/EMPTY bs=1M 2>&1 || echo "dd exit code $? is suppressed"
          rm -f /EMPTY
        fi'
        EOT
      ,
      # remove public keys and shell history, see: https://aws.amazon.com/articles/how-to-share-and-use-public-amis-in-a-secure-manner/
      "sudo find /root/.*history /home/*/.*history -exec rm -f {} \\; || echo 'no history files found to clean'",
      "sudo find / -name 'authorized_keys' -exec rm -f {} \\; || echo 'no authorized_keys files found to clean'",
      "sync",
    ]
  }
}
