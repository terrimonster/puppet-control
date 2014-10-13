#!/bin/bash

PE_VERSION="3.3.2"

###########################################################
ANSWERS=$1
PE_URL="https://s3.amazonaws.com/pe-builds/released/${PE_VERSION}/puppet-enterprise-${PE_VERSION}-el-6-x86_64.tar.gz"
FILENAME=${PE_URL##*/}
DIRNAME=${FILENAME%*.tar.gz}

## A reasonable PATH
echo "export PATH=$PATH:/usr/local/bin:/opt/puppet/bin" >> /etc/bashrc

## Add host entries for each system
cat > /etc/hosts <<EOH
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain
::1 localhost localhost.localdomain localhost6 localhost6.localdomain
192.168.137.10 xmaster.vagrant.vm xmaster
192.168.137.14 xagent.vagrant.vm xagent
EOH

## Download and extract the PE installer
cd /vagrant/provision/pe || (echo "/vagrant/provision/pe doesn't exist." && exit 1)
if [ ! -f $FILENAME ]; then
  curl -O ${PE_URL} || (echo "Failed to download ${PE_URL}" && exit 1)
else
  echo "${FILENAME} already present"
fi

if [ ! -d ${DIRNAME} ]; then
  tar zxf ${FILENAME} || (echo "Failed to extract ${FILENAME}" && exit 1)
else
  echo "${DIRNAME} already present"
fi

## Install PE with a specified answer file
if [ ! -d '/opt/puppet/' ]; then
  # Assume puppet isn't installed
  /vagrant/provision/pe/${DIRNAME}/puppet-enterprise-installer \
    -a /vagrant/provision/pe/answers/${ANSWERS}
else
  echo "/opt/puppet exists. Assuming it's already installed."
fi

## Bootstrap the master
if [ "$1" == 'master.txt' ]; then

  ## Install some prerequisites
  yum install -y git
  /opt/puppet/bin/gem install r10k

  ## Use the control repo for bootstrapping
  mkdir -p /etc/puppetlabs/puppet/environments
  ln -s /vagrant/code/control /etc/puppetlabs/puppet/environments/production
  cd /etc/puppetlabs/puppet/environments/production/
  /opt/puppet/bin/r10k puppetfile install -v

  /opt/puppet/bin/puppet apply -e 'include profile::puppet::master' \
    --modulepath=./modules:./site

  if [ $? -eq 0 ]; then
    if [ -f "/root/.ssh/id_rsa.pub" ]; then
      echo "################################################################"
      echo "Copy the following SSH pubkey to your clipboard:"
      echo
      cat /root/.ssh/id_rsa.pub
      echo
      echo "################################################################"
      echo "This key should be added to your git server."
    fi
  else
    echo "The master failed to apply its role."
  fi
fi

sudo /opt/puppet/bin/puppet agent -t
