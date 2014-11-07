filebucket { 'main':
  server => $::servername,
  path   => false,
}

File { backup => 'main' }

Package {
  allow_virtual => true,
}

node 'xmaster.vagrant.vm' {
  include role::puppet::master
}

node 'xagent.vagrant.vm' {
  include role::base
}

node default {
  ## Using hiera to classify our nodes
  hiera_include('classes')
}
