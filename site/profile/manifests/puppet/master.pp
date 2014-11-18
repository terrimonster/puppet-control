class profiles::puppet::master (
    $hiera_eyaml = false,
    $autosign = false,
    $environmentpath = "${::settings::confdir}/environments",
    $deploy_pub_key = "",
    $deploy_private_key = "",
    $r10k_version = '1.3.4',
) inherits profiles::puppet::params {
  validate_string($remote)
  validate_bool($hiera_eyaml,$autosign)
  File {
    owner => 'root',
    group => 'root',
  }

  class { 'hiera':
    hierarchy => [
      'nodes/%{clientcert}',
      'app_tier/%{app_tier}',
      'env/%{environment}',
      'global',
    ],
    datadir   => $profiles::puppet::params::hieradir,
    backends  => $backends,
    eyaml     => $hiera_eyaml,
    notify    => Service['pe-httpd'],
  }

  class { 'r10k':
    version => $r10k_version,
    sources  => {
      'control' => {
        'remote'  => $profiles::puppet::params::remote,
        'basedir' => $environmentpath,
        'prefix'  => false,
      },
    },
    purgedirs         => [$environmentpath],
    manage_modulepath => false,
    mcollective       => true,
    notify            => Service['pe-httpd'],
  }

  if $autosign {
    file { 'autosign':
      ensure  => 'present',
      content => '*.vagrant.vm',
      path    => "${::settings::confdir}/autosign.conf",
    }
  }

  file { $environmentpath :
    ensure => 'directory',
  }



  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => $profiles::puppet::params::basemodulepath,
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
    mode   => '0700',
  }

  if $deploy_pub_key {
    # private key
    file { '/root/.ssh/r10k-control-repo-id_rsa':
      ensure  => present,
      mode    => '600',
      content => $deploy_private_key,
    }
    # private key
    file { '/root/.ssh/r10k-control-repo-id_rsa.pub':
      ensure  => present,
      mode    => '600',
      content => $deploy_pub_key,
    }
    # ssh config
    file { '/root/.ssh/config':
      ensure => present,
      mode => '600',
      source => 'puppet:///modules/profiles/ssh_master_config',
    }
  } else {
    ## Create an SSH keypair
    exec { 'create_ssh_keys':
      path    => [ '/usr/bin' ],
      command => "ssh-keygen -f /root/.ssh/id_rsa -N ''",
      creates => '/root/.ssh/id_rsa',
      require => File['/root/.ssh'],
    }
  }

  ## Firewall rules for PE
  firewall { '100 allow puppet':
    port   => [8140, 61613, 443],
    proto  => 'tcp',
    action => 'accept',
  }

}
