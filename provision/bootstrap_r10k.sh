#!/bin/bash

HOSTNAME=`hostname`

if [[ $HOSTNAME =~ vagrant ]]; then
  MODPATH='/vagrant/site'
else
  MODPATH='/etc/puppetlabs/puppet/environments/production/site'
fi

/opt/puppet/bin/puppet apply -e 'include profile::puppet::r10k' --modulepath=$MODPATH

rm -rf /etc/puppetlabs/puppet/environments/production

/opt/puppet/bin/r10k deploy environment -p production --puppetfile \
  --verbose debug

/opt/puppet/bin/puppet agent -t
