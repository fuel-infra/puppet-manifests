# Class: opentracker
#
class opentracker (
  $listen = '0.0.0.0:8080',
  $rootdir = '/var/lib/opentracker',
  $user = 'opentracker',
  $apply_firewall_rules = false,
  $firewall_allow_sources = [],
) {
  include opentracker::params

  $config_file = $opentracker::params::config_file
  $packages = $opentracker::params::packages
  $service = $opentracker::params::service

  package { $packages :
    ensure => 'present',
  }

  file { $config_file :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('opentracker/opentracker.conf.erb'),
    require => Package[$packages],
  }~>
  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  if $firewall_allow_sources {
    include firewall_defaults::pre
    Class['firewall_defaults::pre']->
      firewall { '1000 allow TCP connections to opentracker' :
        dport  => 8080,
        proto  => 'tcp',
        action => 'accept',
      }->
      firewall { '1000 allow UDP connections to opentracker' :
        dport  => 6969,
        proto  => 'udp',
        action => 'accept',
      }
  }
}
