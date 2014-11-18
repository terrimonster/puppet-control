#!/bin/bash

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
