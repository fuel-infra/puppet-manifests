class postgresql {
  include postgresql::params

  $packages = $postgresql::params::packages
  $service = $postgresql::params::service

  package { $packages:
    ensure => 'latest',
  }
  package { 'logrotate':
    ensure => '3.7.8-6ubuntu5',
  }

  file { 'pg_hba.conf':
    path => '/etc/postgresql/9.1/main/pg_hba.conf',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('postgresql/pg_hba.conf.erb'),
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  File['allow-unauthenticated.conf'] -> Package[$packages] -> File['pg_hba.conf'] ~> Service[$service]
  File['pg_hba.conf'] ~> Service[$service]
}
