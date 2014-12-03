# this file is for negotiating sensible
# defaults for your profile::puppet::*
# classes. This makes your code less messy
# and follows puppet best practices.
class profile::puppet::params {

  $remote = 'git@github.com:terrimonster/puppet-control.git'

  case $::settings::server {
    'xmaster.vagrant.vm': {
      $hieradir = '/vagrant/hieradata'
      $basemodulepath = "/vagrant/site:${::settings::confdir}/modules:/opt/puppet/share/puppet/modules"
    }
    default: {
      $hieradir = '"/etc/puppetlabs/puppet/environments/%{::environment}/hieradata"'
      $basemodulepath = "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules"
    }
  }
}
