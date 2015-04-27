#!/bin/bash

rm -rf /etc/puppetlabs/puppet/environments/production

/opt/puppet/bin/puppet module install zack-r10k --modulepath \
  /etc/puppetlabs/puppet/modules --ignore-requirements

cat > /tmp/newsite.pp <<EOM
case $::settings::server {
  'xmaster.vagrant.vm': {
    \$remote = '/vagrant'
  }
  default: {
    \$remote = 'git@github.com:terrimonster/puppet-control.git'
  }
}
class { 'r10k':
  version => '1.5.1',
  remote => \$remote,
}
EOM
echo "APPLYING R10K"
/opt/puppet/bin/puppet apply /tmp/newsite.pp \
  --modulepath=/etc/puppetlabs/puppet/modules

/opt/puppet/bin/r10k deploy environment -p production --puppetfile \
  --verbose debug
echo "Sleeping for 10 seconds while prod env is recognized"

sleep 10

/opt/puppet/bin/puppet agent -t
