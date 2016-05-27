# -*- mode: ruby -*-
# vi: set ft=ruby :

abort "Install oscar with 'vagrant plugin install oscar'" unless defined? Oscar

Vagrant.configure('2', &Oscar.run(File.expand_path('../config', __FILE__))) if defined? Oscar
