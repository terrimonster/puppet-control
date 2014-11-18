# this file is for negotiating sensible
# defaults for your profile::puppet::*
# classes. This makes your code less messy
# and follows puppet best practices.
class profile::puppet::params {
  case $::settings::server {
    'xmaster.vagrant.vm': {
      $remote = '/vagrant'
      $hieradir = '/vagrant/hieradata'
      $basemodulepath = "/vagrant/site:${::settings::confdir}/modules:/opt/puppet/share/puppet/modules"
    }
    default: {
      $remote = 'git@github.com:terrimonster/puppet-control.git'
      $hieradir = '"/etc/puppetlabs/puppet/environments/%{::environment}/hieradata"'
      $basemodulepath = "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules"
    }
  }
}
