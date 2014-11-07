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
192.168.137.10 xmaster.vagrant.vm xmaster puppet
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

  ## deploy keys

  mkdir -p /root/.ssh

  cp /vagrant/provision/keys/r10k-control-repo-id_rsa \
    /root/.ssh/r10k-control-repo-id_rsa

  cp /vagrant/provision/keys/r10k-control-repo-id_rsa.pub \
    /root/.ssh/r10k-control-repo-id_rsa.pub

  cp /vagrant/provision/keys/config /root/.ssh/config

  ###
  chmod 600 /root/.ssh/r10k*
  chmod 600 /root/.ssh/config

  ## Use the control repo for bootstrapping
  mkdir -p /etc/puppetlabs/puppet/environments

  /opt/puppet/bin/puppet resource ini_setting environmentpath ensure=present \
    path=/etc/puppetlabs/puppet/puppet.conf section=main \
    setting=environmentpath value=/etc/puppetlabs/puppet/environments

  service pe-httpd restart

  /opt/puppet/bin/puppet module install zack-r10k --modulepath \
    /etc/puppetlabs/puppet/modules --ignore-requirements

  cat > /tmp/newsite.pp <<EOM
  class { 'r10k':
    version => '1.3.4',
    remote => 'git@github.com:terrimonster/puppet-control.git',
  }
EOM
  echo "APPLYING R10K"
  /opt/puppet/bin/puppet apply /tmp/newsite.pp \
    --modulepath=/etc/puppetlabs/puppet/modules

  /opt/puppet/bin/r10k deploy environment -p production --puppetfile \
    --verbose debug

  /opt/puppet/bin/puppet agent -t

  echo "All done! Now ssh in using vagrant ssh xmaster and sudo to root!"

fi
