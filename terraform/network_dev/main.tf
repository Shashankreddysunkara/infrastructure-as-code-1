##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  shared_credentials_file = "${var.aws_shared_credentials_file}"
}

##############################################################################
# Remote state
##############################################################################

data "terraform_remote_state" "vpc" {
    backend = "s3"
    config {
        bucket = "nextbreakpoint-terraform-state"
        region = "${var.aws_region}"
        key = "vpc.tfstate"
    }
}

##############################################################################
# Public Subnets
##############################################################################

resource "aws_route_table" "network_dev_public" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.terraform_remote_state.vpc.network-internet-gateway-id}"
  }

  tags {
    Name = "dev public route table"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_dev_public_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_dev_public_subnet_cidr_a}"

  tags {
    Name = "dev public subnet a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "network_dev_public_a" {
  subnet_id = "${aws_subnet.network_dev_public_a.id}"
  route_table_id = "${aws_route_table.network_dev_public.id}"
}

##############################################################################
# NAT Boxes
##############################################################################

resource "aws_security_group" "network_nat" {
  name = "NAT private dev"
  description = "NAT security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.vpc.network-vpc-cidr}"]
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "NAT security group dev"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "network_nat_a" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.amazon_nat_ami, var.aws_region)}"

  subnet_id = "${aws_subnet.network_dev_public_a.id}"
  associate_public_ip_address = "true"
  security_groups = ["${aws_security_group.network_nat.id}"]
  key_name = "${var.key_name}"
  count = "1"

  source_dest_check = false

  connection {
    # The default username for our AMI
    user = "ec2-user"
    type = "ssh"
    key_file = "${var.key_path}"
  }

  tags {
    Name = "nat_box_dev_a"
    Stream = "${var.stream_tag}"
  }
}

##############################################################################
# Private subnets
##############################################################################

resource "aws_route_table" "network_dev_private_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  route {
    vpc_peering_connection_id = "${data.terraform_remote_state.vpc.network-to-bastion-peering-connection-id}"
    cidr_block = "${data.terraform_remote_state.vpc.bastion-vpc-cidr}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.network_nat_a.id}"
    #nat_gateway_id = "${aws_nat_gateway.net_gateway_a.id}"
  }

  tags {
    Name = "dev private route table a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_subnet" "network_dev_private_a" {
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"
  availability_zone = "${format("%s%s", var.aws_region, "a")}"
  cidr_block = "${var.aws_network_dev_private_subnet_cidr_a}"

  tags {
    Name = "dev private subnet a"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_route_table_association" "network_dev_private_a" {
  subnet_id = "${aws_subnet.network_dev_private_a.id}"
  route_table_id = "${aws_route_table.network_dev_private_a.id}"
}

