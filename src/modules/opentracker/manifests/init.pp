class opentracker {
  include opentracker::params

  $config_file = $opentracker::params::config_file
  $packages = $opentracker::params::packages
  $pre_packages = $opentracker::params::pre_packages
  $service = $opentracker::params::service

  package { $pre_packages :
    ensure => latest,
  }

  package { $packages :
    ensure => latest,
  }

  file { $config_file :
    path => '/etc/opentracker.conf',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('opentracker/opentracker.conf.erb'),
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Class['firewall_defaults::pre'] ->
    firewall { '300 allow connections to opentracker' :
      dport => 8080,
      action => 'accept',
    }

  Package[$pre_packages] ->
    Package[$packages] ->
    File[$config_file] ->
    Firewall['300 allow connections to opentracker'] ~>
    Service[$service]

  File[$config_file] ->
    Firewall['300 allow connections to opentracker'] ~>
    Service[$service]
}
