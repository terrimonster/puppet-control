class profile::upgrade (
  $version,
  $puppetmaster,
){
  yumrepo { 'puppetlabs-pepackages':
    ensure    => 'present',
    baseurl   => "https://${puppetmaster}:8140/packages/${version}/el-6-x86_64",
    descr     => 'Puppet Labs PE Packages  - ',
    enabled   => '1',
    gpgcheck  => '1',
    gpgkey    => "https://${puppetmaster}:8140/packages/GPG-KEY-puppetlabs",
    proxy     => '_none_',
    sslverify => 'False',
  }

 $packages = ['pe-agent','pe-augeas','pe-facter','pe-hiera','pe-libldap','pe-libyaml','pe-openssl',
    'pe-puppet','pe-puppet-enterprise-release','pe-ruby','pe-ruby-ldap','pe-ruby-rgen']

  package { $packages:
    ensure => latest,
    require => yumrepo['puppetlabs-pepackages'],
  }
}
