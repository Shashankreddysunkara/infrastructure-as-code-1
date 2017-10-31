#cloud-config
manage_etc_hosts: True
disk_setup:
   ${volume_name}:
       table_type: 'mbr'
       layout:
           - [100, 82]
       overwrite: True
fs_setup:
  - label: elasticsearch
    filesystem: 'ext4'
    device: '${volume_name}1'
mounts:
  - [ ${volume_name}1, "/pipeline", "ext4", "defaults,nofail", "0", "2" ]
runcmd:
  - sudo usermod -aG docker ubuntu
  - sudo mkdir -p /filebeat/config
  - sudo mkdir -p /filebeat/secrets
  - sudo mkdir -p /consul/secrets
  - sudo mkdir -p /consul/config
  - sudo mkdir -p /mysql/scripts
  - sudo mkdir -p /mysql/logs
  - sudo mkdir -p /jenkins/logs
  - sudo mkdir -p /sonarqube/logs
  - sudo mkdir -p /artifactory/logs
  - sudo mkdir -p /pipeline/mysql
  - sudo mkdir -p /pipeline/jenkins
  - sudo mkdir -p /pipeline/sonarqube
  - sudo mkdir -p /pipeline/artifactory
  - sudo chown -R ubuntu:ubuntu /filebeat
  - sudo chown -R ubuntu:ubuntu /consul
  - sudo chown -R ubuntu:ubuntu /mysql
  - sudo chown -R ubuntu:ubuntu /jenkins
  - sudo chown -R ubuntu:ubuntu /sonarqube
  - sudo chown -R ubuntu:ubuntu /artifactory
  - sudo chown -R ubuntu:ubuntu /pipeline
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/ca_cert.pem /filebeat/secrets/ca_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_cert.pem /filebeat/secrets/client_cert.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/filebeat/client_key.pem /filebeat/secrets/client_key.pem
  - aws s3 cp s3://${bucket_name}/environments/${environment}/consul/ca_cert.pem /consul/secrets/ca_cert.pem
  - export HOST_IP_ADDRESS=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`
  - sudo curl -L -o mysql-connector-java-${mysqlconnector_version}.zip https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${mysqlconnector_version}.zip
  - sudo unzip mysql-connector-java-${mysqlconnector_version}.zip
  - sudo -u ubuntu docker run -d --name=mysql --restart unless-stopped -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -p 3306:3306 --net=host -v /pipeline/mysql:/var/lib/mysql -d mysql:latest
  - sudo -u ubuntu docker run -d --name=consul --restart unless-stopped --env HOST_IP_ADDRESS=$HOST_IP_ADDRESS --net=host -v /consul/config:/consul/config consul:latest agent -bind=$HOST_IP_ADDRESS -client=$HOST_IP_ADDRESS -node=pipeline-$HOST_IP_ADDRESS -retry-join=${consul_hostname} -datacenter=${consul_datacenter} -encrypt=${consul_secret}
  - sudo -u ubuntu docker run -d --name=jenkins --restart unless-stopped -p 8080:8080 -p 50000:50000 --net=host -e JAVA_OPTS=-Djenkins.install.runSetupWizard=false -v /pipeline/jenkins:/var/jenkins_home jenkins/jenkins:lts
  - sudo -u ubuntu docker exec -i mysql bash -c "sleep 30"
  - sudo -u ubuntu docker exec -i mysql bash -c "mysql -u root" < /mysql/scripts/setup.sql
  - sudo -u ubuntu docker exec -i mysql bash -c "mysqladmin -u root password 'changeme'"
  - sudo -u ubuntu docker run -d --name=sonarqube --restart unless-stopped -p 9000:9000 -p 9092:9092 --net=host -e SONARQUBE_JDBC_USERNAME=sonarqube -e SONARQUBE_JDBC_PASSWORD=password -e SONARQUBE_JDBC_URL="jdbc:mysql://$HOST_IP_ADDRESS/sonar?useUnicode=true&characterEncoding=utf8&useSSL=false" sonarqube:latest
  - sudo -u ubuntu docker run -d --name=artifactory --restart unless-stopped -p 8081:8081 --net=host -e DB_TYPE=mysql -e DB_HOST=$HOST_IP_ADDRESS -e DB_PORT=3306 -e DB_USER=artifactory -e DB_PASSWORD=password -v /mysql-connector-java-${mysqlconnector_version}/mysql-connector-java-${mysqlconnector_version}-bin.jar:/opt/jfrog/artifactory/tomcat/lib/mysql-connector-java-${mysqlconnector_version}-bin.jar -v /pipeline/artifactory:/var/opt/jfrog/artifactory docker.bintray.io/jfrog/artifactory-oss:latest
  - sudo -u ubuntu docker run -d --name=filebeat --restart unless-stopped --net=host -v /filebeat/config/filebeat.yml:/usr/share/filebeat/filebeat.yml -v /mysql/logs:/logs/mysql -v /jenkins/logs:/logs/jenkins -v /sonarqube/logs:/logs/sonarqube -v /artifactory/logs:/logs/artifactory docker.elastic.co/beats/filebeat:${filebeat_version}
write_files:
  - path: /consul/config/consul.json
    permissions: '0644'
    content: |
        {
          "ca_file": "/consul/secrets/ca_cert.pem",
          "verify_outgoing" : true,
          "enable_script_checks": true,
          "leave_on_terminate": true,
          "dns_config": {
            "allow_stale": true,
            "max_stale": "1s",
            "service_ttl": {
              "*": "5s"
            }
          }
        }
  - path: /etc/docker/daemon.json
    permissions: '0644'
    content: |
        {
          "log-driver": "json-file",
          "log-opts": {
            "labels": "production"
          }
        }
  - path: /consul/config/jenkins.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "jenkins",
                "tags": [
                    "http", "jenkins"
                ],
                "port": 8080,
                "checks": [{
                    "id": "1",
                    "name": "Jenkins HTTP",
                    "notes": "Use curl to check the web service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:8080 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /consul/config/jenkins.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "jenkins",
                "tags": [
                    "http", "jenkins"
                ],
                "port": 8080,
                "checks": [{
                    "id": "1",
                    "name": "Jenkins HTTP",
                    "notes": "Use curl to check the service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:8080 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /consul/config/sonarqube.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "sonarqube",
                "tags": [
                    "http", "sonarqube"
                ],
                "port": 9000,
                "checks": [{
                    "id": "1",
                    "name": "SonarQube HTTP",
                    "notes": "Use curl to check the service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:9000 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /consul/config/artifactory.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "artifactory",
                "tags": [
                    "http", "artifactory"
                ],
                "port": 8081,
                "checks": [{
                    "id": "1",
                    "name": "Artifactory HTTP",
                    "notes": "Use curl to check the service every 60 seconds",
                    "script": "curl $HOST_IP_ADDRESS:8081 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /consul/config/mysql.json
    permissions: '0644'
    content: |
        {
            "services": [{
                "name": "mysql",
                "tags": [
                    "tcp", "mysql"
                ],
                "port": 3306,
                "checks": [{
                    "id": "1",
                    "name": "MySQL TCP",
                    "notes": "Use nc to check the service every 60 seconds",
                    "script": "nc -zv $HOST_IP_ADDRESS 3306 >/dev/null 2>&1",
                    "interval": "60s"
                }]
            }]
        }
  - path: /filebeat/config/filebeat.yml
    permissions: '0644'
    content: |
        filebeat.prospectors:
        - input_type: log
          paths:
          - /logs/mysql/*.log
          - /logs/jenkins/*.log
          - /logs/sonarqube/*.log
          - /logs/artifactory/*.log

        output.logstash:
          hosts: ["${logstash_host}:5044"]
          ssl.certificate_authorities: ["/filebeat/secrets/ca_cert.pem"]
          ssl.certificate: "/filebeat/secrets/client_cert.pem"
          ssl.key: "/filebeat/secrets/client_key.pem"
  - path: /mysql/scripts/setup.sql
    permissions: '0644'
    content: |
        DROP DATABASE IF EXISTS `sonar`;
        CREATE DATABASE `sonar` CHARACTER SET utf8 COLLATE utf8_bin;
        DROP DATABASE IF EXISTS `artdb`;
        CREATE DATABASE `artdb` CHARACTER SET utf8 COLLATE utf8_bin;
        CREATE USER IF NOT EXISTS 'sonarqube' IDENTIFIED BY 'password' PASSWORD EXPIRE NEVER;
        CREATE USER IF NOT EXISTS 'artifactory' IDENTIFIED BY 'password' PASSWORD EXPIRE NEVER;
        GRANT ALL ON `sonar`.* TO 'sonarqube'@'%';
        GRANT ALL ON `artdb`.* TO 'artifactory'@'%';
        FLUSH PRIVILEGES;
