# Class: build_fuel_iso
#
class build_fuel_iso (
  $external_host = false,
) {
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages

  ensure_packages($packages)

  if ! defined(Package['multistrap']) {
    package { 'multistrap' :
      ensure => '2.1.6ubuntu3'
    }
  }

  # Meta(pinnings, holds, etc.)
  # apt::hold supported in puppetlabs-apt >= 1.5:
  # apt::hold { 'multistrap': version => '2.1.6ubuntu3' }
  apt::pin { 'multistrap' :
    packages => 'multistrap',
    version  => '2.1.6ubuntu3',
    priority => 1000,
  }
  # /Meta(pinnings, holds, etc.)

  exec { 'install-grunt-cli' :
    command   => '/usr/bin/npm install -g grunt-cli',
    logoutput => on_failure,
  }

  file { 'jenkins-sudo-for-build_iso' :
    path    => '/etc/sudoers.d/build_fuel_iso',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('build_fuel_iso/sudoers_d_build_fuel_iso.erb')
  }

  if $external_host {
    firewall { '010 accept all to docker0 interface':
      proto   => 'all',
      iniface => 'docker0',
      action  => 'accept',
      require => Package[$packages],
    }
  }

  Package[$packages]->
    Exec['install-grunt-cli']->
    File['jenkins-sudo-for-build_iso']
}
