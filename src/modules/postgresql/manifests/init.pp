class postgresql {
  include postgresql::params

  $config = $postgresql::params::config
  $packages = $postgresql::params::packages
  $service = $postgresql::params::service

  package { $packages:
    ensure => latest,
  }

  file { $config :
    path => $config,
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

  Class['dpkg'] ->
    Package[$packages] ->
    File[$config] ~>
    Service[$service]

  File[$config] ~>
    Service[$service]
}
