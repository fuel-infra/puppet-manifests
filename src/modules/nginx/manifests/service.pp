class nginx::service {
  include nginx::params

  $service = $nginx::params::service

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }
}
