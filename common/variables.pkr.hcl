variable "security_groups" {
  default = ["default"]
}

variable "networks" {
  type = list(string)
}

variable "floating_ip_network" {
  type    = string
  default = null
}

variable "ssh_ip_version" {
  default = 4
}

variable "image_visibility" {
  default = "public"
}

variable "image_tags" {
  default = ["packer-base"]
}

variable "flavor" {
  default = "m1.small"
}

variable "config_drive" {
  default = false
}

packer {
  required_plugins {
    openstack = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/openstack"
    }
  }
}
