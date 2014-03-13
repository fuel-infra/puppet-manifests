class transmission_daemon {
  include transmission_daemon::params

  $config = $transmission_daemon::params::config
  $packages = $transmission_daemon::params::packages
  $service = $transmission_daemon::params::service

  package { $packages :
    ensure => 'latest',
  }

  file { "${config}-new" :
    path => "${config}-new",
    ensure => 'present',
    mode => '0644',
    owner => 'root',
    group => 'root',
    content => template('transmission_daemon/settings.json.erb'),
  }

  exec { "${service}-reload" :
    command => "service ${service} stop ; cp ${config}-new ${config} ; service ${service} start",
    provider => 'shell',
    user => 'root',
    refreshonly => true,
  }

  Class['dpkg'] ->
    Package[$packages] ->
    File["${config}-new"] ~>
    Exec["${service}-reload"]

  File["${config}-new"] ~>
    Exec["${service}-reload"]
}
