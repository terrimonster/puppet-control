class profile::puppet::master (
    $hiera_eyaml = false,
    $autosign = false,
    $deploy_pub_key = "",
    $deploy_private_key = "",
    $environmentpath = $::profile::puppet::params::environmentpath,
) inherits profile::puppet::params {
  validate_bool($hiera_eyaml,$autosign)

  include profile::puppet::r10k

  File {
    owner => 'root',
    group => 'root',
  }

  class { 'hiera':
    hierarchy => [
      'dept1_%{::environment}/nodes/%{::fqdn}',
      'dept2_%{::environment}/nodes/%{::fqdn}',
      'dept1_%{::environment}/tier/%{::tieringlevel}',
      'dept2_%{::environment}/tier/%{::tieringlevel}',
      'dept1_%{::environment}/common',
      'dept2_%{::environment}/common ',
      'nodes/%{clientcert}',
      'app_tier/%{app_tier}',
      'env/%{environment}',
      'common',
    ],
    datadir   => $profile::puppet::params::hieradir,
    backends  => $backends,
    eyaml     => $hiera_eyaml,
    notify    => Service['pe-puppetserver'],
  }

  if $autosign {
    file { 'autosign':
      ensure  => 'present',
      content => '*.vagrant.vm',
      path    => "${::settings::confdir}/autosign.conf",
    }
  }

  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => $profile::puppet::params::basemodulepath,
    notify  => Service['pe-puppetserver'],
  }

  ini_setting { 'environmentpath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => $environmentpath,
    notify  => Service['pe-puppetserver'],
  }

}
