#!/bin/bash
DIR=$(pwd)
source bash_alias

cd $DIR/terraform/webserver && tf_destroy

cd $DIR/terraform/pipeline && tf_destroy

cd $DIR/terraform/ecs && tf_destroy

cd $DIR/terraform/kibana && tf_destroy

cd $DIR/terraform/logstash && tf_destroy

cd $DIR/terraform/elasticsearch && tf_destroy

cd $DIR/terraform/consul && tf_destroy

cd $DIR/terraform/dns && tf_destroy

cd $DIR/terraform/secrets && tf_destroy
