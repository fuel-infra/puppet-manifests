class zabbix::agent (
  $zabbix_server = '127.0.0.1',
  $listen_address = '0.0.0.0',
  $listen_port = 10050,
  $log_file = '/var/log/zabbix-agent/zabbix_agentd.log',
  $debug_level = 4,
  $enable_remote_commands = true,
  $log_remote_commands = true,
  $start_agents = 3,
  $server_active = '',
  $refresh_active_checks = 120,
  $hostname = $::fqdn,
  $hostname_item = $::fqdn,
  $max_lines_per_second = 100,
  $allow_root = false,
  $timeout = 5,
  $include = '/etc/zabbix/zabbix_agentd.conf.d/',
  $unsafe_user_parameters = false,
  $enable_firewall = false,
  $firewall_allow_sources = []
) {
  include zabbix::params

  $package = $zabbix::params::agent_package
  $service = $zabbix::params::agent_service

  if ! defined(Package[$package]) {
    package { $package :
      ensure => 'present',
    }
  }

  file { '/etc/zabbix/zabbix_agentd.conf' :
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/zabbix_agentd.conf.erb'),
    require => Package[$package],
  }

  file { '/etc/sudoers.d/zabbix' :
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/sudoers.erb')
  }

  if $enable_firewall {
    $port = 10050
    $proto = 'tcp'

    each($firewall_allow_sources) |$ip| {
      firewall { "1000 allow zabbix connections - src ${ip} ; dst ${proto}/${port}" :
        dport => $port,
        proto => $proto,
        source => $ip,
        action => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
