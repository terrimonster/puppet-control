class profile::base::linux {
  ## We want to be able to manage firewall rules for our demo
  include firewall

  ## We require EPEL for various things
  include epel
}
