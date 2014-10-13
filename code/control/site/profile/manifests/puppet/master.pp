class profile::puppet::master (
    $hiera_eyaml = false,
    $autosign = false,
    $remote = "git@github.com:terrimonster/puppet-control.git"
) {
  validate_string($remote)
  validate_bool($hiera_eyaml,$autosign)
  if $hiera_eyaml {
    ## The hiera-eyaml config. This is added via the hiera class below.
    $hiera_config = [':eyaml:',
    "  :datadir: \"${::settings::confdir}/environments/%{environment}/hieradata\"",

    "  :pkcs7_private_key: ${::settings::confdir}/keys/private_key.pkcs7.pem",
    "  :pkcs7_public_key: ${::settings::confdir}/keys/public_key.pkcs7.pem",
    '  :extension: "yaml"',
    ]

    package { 'hiera-eyaml':
      ensure   => 'installed',
      provider => 'pe_gem',
    }

    file { 'keys_dir':
      ensure => 'directory',
      path   => "${::settings::confdir}/keys",
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0700',
    }

    ## Create an example keypair for hiera-eyaml demo
    exec { 'create_eyaml_keys':
      path    => [ '/opt/puppet/bin' ],
      command => 'eyaml createkeys',
      creates => "${::settings::confdir}/keys/private_key.pkcs7.pem",
      cwd     => $::settings::confdir,
      require => [ Package['hiera-eyaml'], File['keys_dir'] ],
    }
    $backends = ['eyaml', 'yaml']
  } else {
    $backends = ['yaml']
  }
  class { 'hiera':
    hierarchy => [
      'nodes/%{fqdn}',
      'env/%{environment}',
      'common',
    ],
    datadir      => "${::settings::confdir}/environments/%{environment}/hieradata",
    backends     => $backends,
    extra_config => $hiera_eyaml ? {
      true    => join($hiera_config, "\n"),
      false => '',
      default => ''},
    notify       => Service['pe-httpd'],
  }

  class { 'r10k':
    sources  => {
      'control' => {
        'remote'  => $remote,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    },
    purgedirs         => ["${::settings::confdir}/environments" ],
    manage_modulepath => false,
    mcollective       => false,
    notify            => Service['pe-httpd'],
  }

  file { 'autosign':
    ensure  => 'present',
    content => '*.vagrant.vm',
    path    => '/etc/puppetlabs/puppet/autosign.conf',
  }

  file { "${::settings::confdir}/environments":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules",
    notify  => Service['pe-httpd'],
  }

  ini_setting { 'environmentpath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => "${::settings::confdir}/environments",
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
