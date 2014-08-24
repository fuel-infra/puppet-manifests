# Class: uwsgi
#
class uwsgi {
  include uwsgi::params

  $service = $uwsgi::params::service

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  file { '/etc/sysctl.d/10-uwsgi-somaxconn.conf' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('uwsgi/sysctl.conf'),
  }

  exec { 'sysctl-apply' :
    command   => '/sbin/sysctl --system -p',
    logoutput => on_failure,
  }

  File['/etc/sysctl.d/10-uwsgi-somaxconn.conf']->
    Exec['sysctl-apply']~>
    Service[$service]
}
