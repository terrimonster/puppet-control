class profile::puppet::master (
    $hiera_eyaml = false,
    $autosign = false,
    $remote = "git@github.com:terrimonster/puppet-control.git",
    $environmentpath = "${::settings::confdir}/environments",
    $basemodulepath = "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules",
    $hieradir = "${::settings::confdir}/environments/%{environment}/hieradata",
) {
  validate_string($remote)
  validate_bool($hiera_eyaml,$autosign)

  class { 'hiera':
    hierarchy => [
      'nodes/%{fqdn}',
      'appenv/%{appenv}',
      'env/%{environment}',
      'common',
    ],
    datadir   => $hieradir,
    backends  => $backends,
    eyaml     => $hiera_eyaml,
    notify    => Service['pe-httpd'],
  }

  class { 'r10k':
    sources  => {
      'control' => {
        'remote'  => $remote,
        'basedir' => $environmentpath,
        'prefix'  => false,
      },
    },
    purgedirs         => [$environmentpath],
    manage_modulepath => false,
    mcollective       => false,
    notify            => Service['pe-httpd'],
  }

  file { 'autosign':
    ensure  => 'present',
    content => '*.vagrant.vm',
    path    => '/etc/puppetlabs/puppet/autosign.conf',
  }

  file { $environmentpath :
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => $basemodulepath,
    notify  => Service['pe-httpd'],
  }

  ini_setting { 'environmentpath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => $environmentpath,
    notify  => Service['pe-httpd'],
  }

  service { 'pe-httpd':
    ensure => 'running',
    enable => true,
  }

  file { '/root/.ssh':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  ## Create an SSH keypair
  exec { 'create_ssh_keys':
    path    => [ '/usr/bin' ],
    command => "ssh-keygen -f /root/.ssh/id_rsa -N ''",
    creates => '/root/.ssh/id_rsa',
    require => File['/root/.ssh'],
  }

  ## Firewall rules for PE
  firewall { '100 allow puppet':
    port   => [8140, 61613, 443],
    proto  => 'tcp',
    action => 'accept',
  }

}
