# Class: uwsgi
#
# This class deploys UWSGI base.
#
# Parameters:
#   [*package*] - package name to deploy UWSGI
#   [*service*] - UWSGI service name
#   [*somaxconn*] - maximum number of queued connections
#
class uwsgi (
  $package   = $::uwsgi::params::package,
  $service   = $::uwsgi::params::service,
  $somaxconn = $::uwsgi::params::somaxconn,
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
