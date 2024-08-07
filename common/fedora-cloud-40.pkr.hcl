source "openstack" "fedora-cloud-40" {
  flavor              = var.flavor
  networks            = var.networks
  security_groups     = var.security_groups
  floating_ip_network = var.floating_ip_network
  ssh_ip_version      = var.ssh_ip_version
  ssh_username        = "fedora"
  image_visibility    = var.image_visibility
  image_tags          = var.image_tags
  config_drive        = var.config_drive

  external_source_image_url    = "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
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
    os_distro           = "fedora"
    os_version          = "40"
    os_require_quiesce  = "yes"
    os_admin_user       = "fedora"
    hw_qemu_guest_agent = "yes"
    hw_vif_model        = "virtio"
    hw_disk_bus         = "scsi"
    hw_scsi_model       = "virtio-scsi"
  }
}
