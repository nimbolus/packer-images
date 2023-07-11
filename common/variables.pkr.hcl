variable "security_groups" {
  description = "security groups for the Packer instance"
  default     = ["default"]
}

variable "networks" {
  description = "networks for the Packer instance"
  type        = list(string)
}

variable "floating_ip_network" {
  description = "floating IP network for the Packer instance"
  type        = string
  default     = null
}

variable "flavor" {
  description = "flavor for the Packer instance"
  default     = "m1.small"
}

variable "config_drive" {
  description = "use metadata config drive for the Packer instance"
  default     = false
}

variable "ssh_ip_version" {
  description = "IP version used by SSH to connect to the Packer instance"
  default     = 4
}

variable "image_prefix" {
  description = "name prefix for the final image"
  default     = ""
}

variable "image_visibility" {
  description = "visibility of the final image"
  default     = "public"
}

variable "image_tags" {
  description = "tags of the final image"
  default     = ["packer-base"]
}

variable "post_script" {
  description = "optional post script for image customization"
  default     = ["echo 'do nothing'"]
}

packer {
  required_plugins {
    openstack = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/openstack"
    }
  }
}
