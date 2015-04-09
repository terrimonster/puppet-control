class profile::base {
  include ntp
  include profile::puppet::agent
  notify { "This is my cool change!": }
}
