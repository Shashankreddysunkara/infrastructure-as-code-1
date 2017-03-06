###################################################################
# AWS configuration below
###################################################################

### MANDATORY ###
variable "aws_shared_credentials_file" {
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  default = "default"
}

### MANDATORY ###
variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

### MANDATORY ###
variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "stream_tag" {
  default = "terraform"
}

###################################################################
# Maintenance configuration below
###################################################################

### MANDATORY ###
variable "amazon_ubuntu_amis" {
  type = "map"
  default = {
    eu-west-1 = "ami-98ecb7fe"
  }
}

variable "maintenance_profile" {
  default = "maintenance"
}

variable "elasticsearch_device_name" {
  default = "/dev/xvdh"
}
