##############################################################################
# Provider
##############################################################################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 0.1"
}

provider "terraform" {
  version = "~> 0.1"
}

provider "template" {
  version = "~> 0.1"
}

provider "null" {
  version = "~> 0.1"
}

##############################################################################
# Cassandra servers
##############################################################################

resource "aws_security_group" "cassandra_server" {
  name = "cassandra-security-group"
  description = "Cassandra security group"
  vpc_id = "${data.terraform_remote_state.vpc.network-vpc-id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.aws_bastion_vpc_cidr}"]
  }

  ingress {
    from_port = 7000
    to_port = 7001
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 7199
    to_port = 7199
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9042
    to_port = 9042
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9142
    to_port = 9142
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 9160
    to_port = 9160
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8301
    to_port = 8301
    protocol = "tcp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  ingress {
    from_port = 8301
    to_port = 8301
    protocol = "udp"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.aws_network_vpc_cidr}"]
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
    Stream = "${var.stream_tag}"
  }
}

resource "aws_iam_instance_profile" "cassandra_server_profile" {
    name = "cassandra-server-profile"
    role = "${aws_iam_role.cassandra_server_role.name}"
}

resource "aws_iam_role" "cassandra_server_role" {
  name = "cassandra-server-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cassandra_server_role_policy" {
  name = "cassandra-server-role-policy"
  role = "${aws_iam_role.cassandra_server_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

data "template_file" "cassandra_server_user_data_seed" {
  template = "${file("provision/cassandra-seed.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.cassandra_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
  }
}

data "aws_ami" "cassandra" {
  most_recent = true

  filter {
    name = "name"
    values = ["cassandra-${var.cassandra_version}-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.account_id}"]
}

resource "aws_instance" "cassandra_server_a1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_a1.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra-server-a1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_b1.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra-server-b1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c1" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  connection {
    #host = "${element(aws_instance.cassandra_server_c1.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "${data.template_file.cassandra_server_user_data_seed.rendered}"
    ]
  }

  tags {
    Name = "cassandra-server-c1"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_a2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-a-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  tags {
    Name = "cassandra-server-a2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_b2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-b-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  tags {
    Name = "cassandra-server-b2"
    Stream = "${var.stream_tag}"
  }
}

resource "aws_instance" "cassandra_server_c2" {
  instance_type = "${var.cassandra_instance_type}"

  ami = "${data.aws_ami.cassandra.id}"

  subnet_id = "${data.terraform_remote_state.vpc.network-private-subnet-c-id}"
  associate_public_ip_address = "false"
  security_groups = ["${aws_security_group.cassandra_server.id}"]
  key_name = "${var.key_name}"

  iam_instance_profile = "${aws_iam_instance_profile.cassandra_server_profile.id}"

  tags {
    Name = "cassandra-server-c2"
    Stream = "${var.stream_tag}"
  }
}

data "template_file" "cassandra_server_user_data_node" {
  template = "${file("provision/cassandra-node.tpl")}"

  vars {
    aws_region              = "${var.aws_region}"
    security_groups         = "${aws_security_group.cassandra_server.id}"
    consul_log_file         = "${var.consul_log_file}"
    log_group_name          = "${var.log_group_name}"
    log_stream_name         = "${var.log_stream_name}"
    hosted_zone_name        = "${var.hosted_zone_name}"
    cassandra_seeds         = "${aws_instance.cassandra_server_a1.private_ip},${aws_instance.cassandra_server_b1.private_ip},${aws_instance.cassandra_server_c1.private_ip}"
  }
}

resource "null_resource" "cassandra_server_a2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_a"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_a2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_a2.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "sleep 60",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}

resource "null_resource" "cassandra_server_b2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_b"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_b2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_b2.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "sleep 120",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}

resource "null_resource" "cassandra_server_c2" {
  #depends_on = ["aws_volume_attachment.cassandra_volume_attachment_c"]
  depends_on = ["aws_instance.cassandra_server_a1","aws_instance.cassandra_server_b1","aws_instance.cassandra_server_c1"]

  triggers {
    cluster_instance_ids = "${join(",", aws_instance.cassandra_server_c2.*.id)}"
  }

  connection {
    host = "${element(aws_instance.cassandra_server_c2.*.private_ip, 0)}"
    # The default username for our AMI
    user = "ubuntu"
    type = "ssh"
    # The path to your keyfile
    private_key = "${file(var.key_path)}"
    bastion_user = "ec2-user"
    bastion_host = "bastion.${var.public_hosted_zone_name}"
  }

  provisioner "remote-exec" {
    inline = [
        "sleep 180",
        "${data.template_file.cassandra_server_user_data_node.rendered}"
    ]
  }
}

##############################################################################
# Route 53
##############################################################################

resource "aws_route53_record" "cassandra" {
   zone_id = "${data.terraform_remote_state.vpc.hosted-zone-id}"
   name = "cassandra.${var.hosted_zone_name}"
   type = "A"
   ttl = "300"

   records = [
     "${aws_instance.cassandra_server_a1.private_ip}",
     "${aws_instance.cassandra_server_b1.private_ip}",
     "${aws_instance.cassandra_server_c1.private_ip}",
     "${aws_instance.cassandra_server_a2.private_ip}",
     "${aws_instance.cassandra_server_b2.private_ip}",
     "${aws_instance.cassandra_server_c2.private_ip}"
   ]
}
