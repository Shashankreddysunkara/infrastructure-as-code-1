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

variable "log_group_name" {
  default = "terraform"
}

variable "log_stream_name" {
  default = "terraform"
}

variable "public_hosted_zone_name" {
}

###################################################################
# Kibana configuration below
###################################################################

### MANDATORY ###
variable "kibana_amis" {
  type = "map"
}

variable "aws_kibana_instance_type" {
  description = "Kibana instance type."
  default  = "t2.small"
}

### MANDATORY ###
# if you have multiple clusters sharing the same es_environment?
variable "es_cluster" {
  description = "Elastic cluster name"
}

### MANDATORY ###
variable "es_environment" {
  description = "Elastic environment tag for auto discovery"
  default = "terraform"
}

variable "minimum_master_nodes" {
  default = "1"
}

variable "availability_zones" {
  default = "eu-west-1a,eu-west-1b"
}

variable "kibana_log_file" {
  default = "/var/log/kibana.log"
}

variable "kibana_profile" {
  default = "kibanaNode"
}

###################################################################
# Consul configuration below
###################################################################

variable "consul_log_file" {
  default = "/var/log/consul.log"
}
