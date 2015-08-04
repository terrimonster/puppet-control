#!/bin/bash
PUPPETBIN="$(which puppet)"
R10KBIN="$(which r10k)"

HOSTNAME=`hostname`

if [[ $HOSTNAME =~ vagrant ]]; then
  MODPATH='/vagrant/site'
else
  MODPATH='/etc/puppetlabs/puppet/environments/production/site'
fi

${PUPPETBIN} apply -e 'include profile::puppet::r10k' --modulepath=$MODPATH

rm -rf /etc/puppetlabs/puppet/environments/production

${R10KBIN} deploy environment -p production --puppetfile \
  --verbose debug

${PUPPETBIN} agent -t
