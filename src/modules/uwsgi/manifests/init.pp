# Class: uwsgi
#
class uwsgi {
  include uwsgi::params

  $packages = $uwsgi::params::packages
  $service = $uwsgi::params::service


  package { $packages :
    ensure => 'present',
  }->
  file { '/etc/sysctl.d/10-uwsgi-somaxconn.conf' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('uwsgi/sysctl.conf'),
  }->
  exec { 'sysctl-apply' :
    command   => '/sbin/sysctl --system -p',
    logoutput => on_failure,
  }
}
