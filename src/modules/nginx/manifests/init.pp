class nginx {
  include nginx::params

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

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Package[$packages]->
    File['nginx.conf']~>
    Service[$service]

  File['nginx.conf']~>
    Service[$service]
}

