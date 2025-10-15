#!/bin/bash
set -e
apt-get update -y
# install docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-get update -y
apt-get install -y docker.io
usermod -aG docker ubuntu

# install Java & Jenkins
apt-get install -y openjdk-11-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update -y
apt-get install -y jenkins

# install awscli v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# install ecs-cli or use aws ecs update-service
# start services
systemctl enable docker
systemctl start docker
systemctl enable jenkins
systemctl start jenkins

# Note: Jenkins initial admin password at /var/lib/jenkins/secrets/initialAdminPassword
# Optionally create a groovy script to install plugins automatically (add to /var/lib/jenkins/init.groovy.d/)
cat <<'EOF' > /var/lib/jenkins/init.groovy.d/install-plugins.groovy
import jenkins.model.*
import hudson.model.*
def inst = Jenkins.getInstance()
def pm = inst.getPluginManager()
def uc = inst.getUpdateCenter()
def plugins = ["docker-plugin","workflow-aggregator","aws-credentials","aws-java-sdk","amazon-ecr","pipeline-utility-steps","github"]
plugins.each {
  if (!pm.getPlugin(it)) {
    def plugin = uc.getPlugin(it)
    if (plugin) {
      plugin.deploy()
    }
  }
}
inst.save()
EOF

chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
systemctl restart jenkins || true
