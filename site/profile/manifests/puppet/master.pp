class profile::puppet::master (
    $hiera_eyaml = false,
    $autosign = false,
    $environmentpath = $::profile::puppet::params::environmentpath,
) inherits ::profile::puppet::params {
  validate_bool($hiera_eyaml,$autosign)

  include ::profile::puppet::r10k

  File {
    owner => 'root',
    group => 'root',
  }

  class { 'hiera':
    hierarchy => [
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

  ini_setting { 'environmentpath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => $environmentpath,
    notify  => Service['pe-puppetserver'],
  }

}
