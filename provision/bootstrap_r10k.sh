#!/bin/bash

HOSTNAME=`hostname`
if [ -d /opt/puppetlabs ]; then
  # PE 2015.1 and later with AIO paths
  BASEDIR="/opt/puppetlabs"
else
  # PE 3.8 and earlier, without AIO paths
  BASEDIR="/opt/puppet"
fi

if [[ $HOSTNAME =~ vagrant ]]; then
  MODPATH='/vagrant/site'
else
  MODPATH='/etc/puppetlabs/puppet/environments/production/site'
fi

${BASEDIR}/bin/puppet apply -e 'include profile::puppet::r10k' --modulepath=$MODPATH

rm -rf /etc/puppetlabs/puppet/environments/production

${BASEDIR}/bin/r10k deploy environment -p production --puppetfile \
  --verbose debug

${BASEDIR}/bin/puppet agent -t
