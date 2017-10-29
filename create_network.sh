#!/bin/bash
DIR=$(pwd)
source bash_alias

# Create VPC and subnets
cd $DIR/terraform/vpc && tf_init && tf_plan && tf_apply

# Create bastion server
cd $DIR/terraform/bastion && tf_init && tf_plan && tf_apply &
bastion_pid=$!

# Create network routing rules
cd $DIR/terraform/network && tf_init && tf_plan && tf_apply &
network_pid=$!

wait $bastion_pid
wait $network_pid
