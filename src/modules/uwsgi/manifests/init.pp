# Class: uwsgi
#
class uwsgi {
  include uwsgi::params

  $packages = $uwsgi::params::packages
  $service = $uwsgi::params::service


  package { $packages :
    ensure => 'present',
  }->
  sysctl { 'net.core.somaxconn' :
    value => 4096,
  }->
  service { 'uwsgi' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }
}
