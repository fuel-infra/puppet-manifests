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

  if $external_host {
    Class['firewall_defaults::pre'] ->
      firewall { '1000 allow TCP connections to opentracker' :
        dport => 8080,
        proto => 'tcp',
        action => 'accept',
      }->
      firewall { '1000 allow UDP connections to opentracker' :
        dport => 6969,
        proto => 'udp',
        action => 'accept',
      }
  }

  Package[$pre_packages] ->
    Package[$packages] ->
    File[$config_file] ->
    Service[$service]

  File[$config_file] ->
    Service[$service]
}
