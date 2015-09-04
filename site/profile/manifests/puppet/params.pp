# this file is for negotiating sensible
# defaults for your profile::puppet::*
# classes. This makes your code less messy
# and follows puppet best practices.
# $remote = 'git@github.com:terrimonster/puppet-control.git'
class profile::puppet::params {
  $hieradir = '"/etc/puppetlabs/puppet/environments/%{::environment}/hieradata"'
  $basemodulepath = "${::settings::confdir}/modules:/opt/puppetlabs/share/puppet/modules"
  $environmentpath = "${::settings::confdir}/environments"
  case $::settings::server {
    'xmaster.vagrant.vm': {
      $remote = '/vagrant'
    }
    default: {
      $remote = 'https://github.com/marsmensch/puppet-control.git'
    }
  }
}
