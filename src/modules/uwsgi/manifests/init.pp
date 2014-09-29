# Class: uwsgi
#
class uwsgi (
  $service = $uwsgi::params::service,
  $package = $uwsgi::params::package,
  $somaxconn = $uwsgi::params::somaxconn,
) inherits ::uwsgi::params {
  package { $package :
    ensure => 'present',
  }

  sysctl { 'net.core.somaxconn' :
    value => $somaxconn,
  }

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => [
      Package[$package],
      Sysctl['net.core.somaxconn'],
    ],
  }
}
