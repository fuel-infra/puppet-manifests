class nginx {
  include nginx::params

  include nginx::service

  $packages = $nginx::params::packages
  $service = $nginx::params::service

  package { $packages :
    ensure => latest,
  }

  file { 'nginx.conf' :
    path => '/etc/nginx/nginx.conf',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('nginx/nginx.conf.erb'),
  }

  file { 'default.conf-enabled' :
    path => '/etc/nginx/sites-enabled/default',
    ensure => absent,
  }

  file { 'default.conf-available' :
    path => '/etc/nginx/sites-available/default',
    ensure => absent,
  }

  Package[$packages]->
    File['nginx.conf']->
    File['default.conf-available']->
    File['default.conf-enabled']~>
    Class['nginx::service']

  File['nginx.conf']->
    File['default.conf-available']->
    File['default.conf-enabled']~>
    Class['nginx::service']
}
