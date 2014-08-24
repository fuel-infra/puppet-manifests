# Class: puppet::agent
#
class puppet::agent {
  include puppet::params

  include puppet::config

  $packages = $puppet::params::agent_packages
  $service = $puppet::params::service

  realize Package[$packages]

  service { $service :
    ensure => 'stopped',
    enable => false,
  }
}
