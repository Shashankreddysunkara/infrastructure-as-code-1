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

variable "amazon_nat_ami" {
  default = {
    eu-west-1 = "ami-47ecb121"
  }
}

###################################################################
# Subnets configuration below
###################################################################

### MANDATORY ###
variable "aws_network_dev_private_subnet_cidr_a" {
  description = "Private dev subnet A cidr block"
}

### MANDATORY ###
variable "aws_network_dev_public_subnet_cidr_a" {
  description = "Public dev subnet A cidr block"
}

