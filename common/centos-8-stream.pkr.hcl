source "openstack" "centos-8-stream" {
  flavor              = var.flavor
  networks            = var.networks
  security_groups     = var.security_groups
  floating_ip_network = var.floating_ip_network
  ssh_ip_version      = var.ssh_ip_version
  ssh_username        = "centos"
  image_visibility    = var.image_visibility
  image_tags          = var.image_tags
  config_drive        = var.config_drive

  external_source_image_url    = "https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-latest.x86_64.qcow2"
  external_source_image_format = "qcow2"
  external_source_image_properties = {
    hw_disk_bus   = "scsi"
    hw_scsi_model = "virtio-scsi"
  }

  metadata = {
    architecture        = "x86_64"
    hypervisor_type     = "qemu"
    vm_mode             = "hvm"
    os_type             = "linux"
    os_distro           = "centos"
    os_version          = "8-stream"
    os_require_quiesce  = "yes"
    os_admin_user       = "centos"
    hw_qemu_guest_agent = "yes"
    hw_vif_model        = "virtio"
    hw_disk_bus         = "scsi"
    hw_scsi_model       = "virtio-scsi"
  }
}
