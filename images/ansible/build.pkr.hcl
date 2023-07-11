build {
  name = "ansible"

  source "source.openstack.centos-8-stream" {
    image_name = "${var.image_prefix}centos-8-stream-ansible"
  }
  source "source.openstack.centos-9-stream" {
    image_name = "${var.image_prefix}centos-9-stream-ansible"
  }
  source "source.openstack.debian-11" {
    image_name = "${var.image_prefix}debian-11-ansible"
  }
  source "source.openstack.debian-12" {
    image_name = "${var.image_prefix}debian-12-ansible"
  }
  source "source.openstack.fedora-cloud-38" {
    image_name = "${var.image_prefix}fedora-cloud-38-ansible"
  }
  source "source.openstack.ubuntu-20_04" {
    image_name = "${var.image_prefix}ubuntu-20.04-ansible"
  }
  source "source.openstack.ubuntu-22_04" {
    image_name = "${var.image_prefix}ubuntu-22.04-ansible"
  }

  # wait for cloud-init
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"
    ]
  }

  # upgrade and install base packages
  provisioner "shell" {
    only = [
      "openstack.centos-8-stream",
      "openstack.centos-9-stream",
      "openstack.fedora-cloud-38",
    ]
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y qemu-guest-agent git python3-pip",
      "sudo pip3 install ansible-core hvac",
    ]
  }
  provisioner "shell" {
    only = [
      "openstack.debian-11",
      "openstack.debian-12",
      "openstack.ubuntu-20_04",
      "openstack.ubuntu-22_04",
    ]
    inline = [
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y qemu-guest-agent git",
    ]
  }
  provisioner "shell" {
    only = [
      "openstack.debian-11",
      "openstack.ubuntu-20_04",
      "openstack.ubuntu-22_04",
    ]
    inline = [
      "sudo apt-get install -y python3-pip",
      "sudo pip3 install ansible-core hvac",
    ]
  }
  provisioner "shell" {
    only = [
      # debian 12 does not allow using pip without venv
      "openstack.debian-12",
    ]
    inline = [
      "sudo apt-get install -y ansible-core python3-hvac",
      "sudo ln -s /usr/bin/ansible-playbook /usr/local/bin/ansible-playbook",
      "sudo ln -s /usr/bin/ansible-galaxy /usr/local/bin/ansible-galaxy",
    ]
  }

  # enable unattended upgrades
  provisioner "shell" {
    only = [
      "openstack.debian-11",
      "openstack.debian-12",
      "openstack.ubuntu-20_04",
      "openstack.ubuntu-22_04",
    ]
    inline = [
      "sudo apt-get install -y unattended-upgrades",
      "sudo dpkg-reconfigure -f noninteractive unattended-upgrades",
    ]
  }
  provisioner "shell" {
    only = [
      "openstack.centos-8-stream",
      "openstack.centos-9-stream",
      "openstack.fedora-cloud-38",
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
      "sudo /usr/local/bin/ansible-galaxy install -r /tmp/ssh-ca-auth/requirements.yml",
      "sudo rm -r /tmp/ssh-ca-auth",
      "sudo bash -c 'if command -v restorecon &> /dev/null; then restorecon /etc/systemd/system/ssh-ca-auth.service; fi'",
      "sudo systemctl enable ssh-ca-auth",
    ]
  }

  # post script
  provisioner "shell" {
    inline = var.post_script
  }

  # empty resolv.conf - https://git.centos.org/centos/kickstarts/pull-request/12#
  provisioner "shell" {
    only = [
      "openstack.centos-8-stream",
      "openstack.centos-9-stream",
    ]
    inline = [
      "echo | sudo tee /etc/resolv.conf"
    ]
  }

  # cleaning for smaller image
  provisioner "shell" {
    only = [
      "openstack.centos-8-stream",
      "openstack.centos-9-stream",
      "openstack.fedora-cloud-38",
    ]
    inline = [
      "sudo dnf autoremove -y && dnf clean all && sudo rm -rf /var/cache/yum",
    ]
  }
  provisioner "shell" {
    only = [
      "openstack.debian-11",
      "openstack.debian-12",
      "openstack.ubuntu-20_04",
      "openstack.ubuntu-22_04",
    ]
    inline = [
      "sudo apt-get autoclean",
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
