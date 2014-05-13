class uwsgi {
  include uwsgi::params

  $service = $uwsgi::params::service

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }
}
