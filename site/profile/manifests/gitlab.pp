class profile::gitlab {
  ## Gitlab prerequisites
  package { [ 'openssh-server', 'postfix', 'git' ]:
    ensure => 'present',
  }

  package { 'puppet-lint':
    ensure => present,
    provider => 'pe_gem',
  }

  file { '/usr/local/bin/puppet-lint':
    ensure => link,
    target => '/opt/puppet/bin/puppet-lint',
  }

  ## This rpm is an omnibus installer
  package { 'gitlab':
    ensure   => 'present',
    provider => 'rpm',
    source   => 'https://downloads-packages.s3.amazonaws.com/centos-6.5/gitlab-7.0.0_omnibus-1.el6.x86_64.rpm',
    require  => [ Package['openssh-server'], Package['postfix'] ],
  }

  ## Change the gitlab server address url
  file_line { 'gitlab_address':
    ensure  => 'present',
    path    => '/etc/gitlab/gitlab.rb',
    line    => "external_url 'http://gitlab.vagrant.vm'",
    match   => '^external_url',
    notify  => Exec['gitlab_reconfigure'],
    require => Package['gitlab'],
  }

  ## Gitlab installation items
  exec { 'gitlab_reconfigure':
    command     => 'gitlab-ctl reconfigure',
    path        => [ '/usr/bin' ],
    refreshonly => true,
  }

  exec { 'install_gitlab_shell':
    command     => '/root/gitlab_shell/bin/install',
    refreshonly => true,
  }

}
