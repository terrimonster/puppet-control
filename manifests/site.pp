filebucket { 'main':
  server => $::servername,
  path   => false,
}

File { backup => 'main' }

Package {
  allow_virtual => true,
}

node default {
  ## Using hiera to classify our nodes
  hiera_include('classes')
}
