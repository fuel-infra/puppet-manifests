class puppet::agent {
  include puppet::params

  include puppet::config

  $packages = $puppet::params::packages
  $service = $puppet::params::service

  package { $packages :
    ensure => present,
  }

  service { $service :
    ensure => 'stopped',
    enable => false,
  }
}
