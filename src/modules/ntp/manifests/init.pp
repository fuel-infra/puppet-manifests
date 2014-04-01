class ntp {
  include ntp::params

  $config = $ntp::params::config
  $packages = $ntp::params::packages
  $restrict = $ntp::params::restrict
  $servers = $ntp::params::servers
  $service = $ntp::params::service

  package { $packages :
    ensure => latest,
  }

  file { $config :
    path => '/etc/ntp.conf',
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('ntp/ntp.conf.erb')
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Package[$packages]->
    File[$config]~>
    Service[$service]

  File[$config]~>
    Service[$service]
}
