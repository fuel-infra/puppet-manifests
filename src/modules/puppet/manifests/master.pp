# Class: puppet::master
#
class puppet::master (
  $apply_firewall_rules = false,
  $firewall_allow_sources = [],
  $hiera_backends = ['yaml'],
  $hiera_config = '/etc/hiera.yaml',
  $hiera_config_template = 'puppet/hiera.yaml.erb',
  $hiera_hierarchy = ['common'],
  $hiera_json_datadir = '/var/lib/hiera',
  $hiera_logger = 'console',
  $hiera_merge_behavior = 'deep',
  $hiera_yaml_datadir = '/var/lib/hiera',
  $puppet_config = '/etc/puppet/puppet.conf',
  $puppet_config_template = 'puppet/puppet.conf.erb',
  $puppet_environment = 'production',
  $puppet_master_package = 'puppetmaster',
  $puppet_master_service = 'puppetmaster',
  $puppet_server = '',
) {
  if (!defined(File[$puppet_config])) {
    file { $puppet_config :
      ensure  => 'present',
      mode    => '0644',
      owner   => 'puppet',
      group   => 'puppet',
      content => template(
        'puppet/puppet.conf.erb', 'puppet/puppet-master.conf.erb'),
    }
  } else {
    File <| title == $puppet_config |> {
      ensure  => 'present',
      mode    => '0644',
      owner   => 'puppet',
      group   => 'puppet',
      content => template(
        'puppet/puppet.conf.erb', 'puppet/puppet-master.conf.erb'),
    }
  }

  if (!defined(Package[$puppet_master_package])) {
    package { $puppet_master_package :
      ensure => 'present',
    }
  }

  if ($hiera_merge_behaviour == 'deeper') {
    package { 'deep_merge' :
      ensure   => 'present',
      provider => 'gem',
    }
  }

  service { $puppet_master_service :
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => [
      Package[$puppet_master_package],
      File[$puppet_config]
    ]
  }

  file { $hiera_config :
    ensure  => 'present',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0400',
    content => template($hiera_config_template),
    require => Package[$puppet_master_package]
  }

  if $apply_firewall_rules {
    $port = 8140
    $proto = 'tcp'

    each($firewall_allow_sources) |$ip| {
      firewall { "1000 puppetmaster - src ${ip} ; dst ${proto}/${port}" :
        dport   => $port,
        proto   => $proto,
        source  => $ip,
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
