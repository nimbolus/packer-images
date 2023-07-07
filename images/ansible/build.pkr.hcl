build {
  name = "ansible"

  source "source.openstack.centos-8-stream" {
    image_name = "centos-8-stream-ansible-test"
  }
  source "source.openstack.centos-9-stream" {
    image_name = "centos-9-stream-ansible-test"
  }
  source "source.openstack.debian-11" {
    image_name = "debian-11-ansible-test"
  }
  source "source.openstack.debian-12" {
    image_name = "debian-12-ansible-test"
  }
  source "source.openstack.fedora-cloud-38" {
    image_name = "fedora-cloud-38-ansible-test"
  }
  source "source.openstack.ubuntu-20_04" {
    image_name = "ubuntu-20.04-ansible-test"
  }
  source "source.openstack.ubuntu-22_04" {
    image_name = "ubuntu-22.04-ansible-test"
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
      "sudo apt-get install -y qemu-guest-agent git python3-pip",
    ]
  }

  # install ansible
  provisioner "shell" {
    inline = [
      "sudo pip3 install ansible-base hvac",
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
