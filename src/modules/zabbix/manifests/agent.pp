# Class: zabbix::agent
#
class zabbix::agent (
  $zabbix_server = $::zabbix::params::agent_zabbix_server,
  $listen_address = $::zabbix::params::agent_listen_address,
  $listen_port = $::zabbix::params::agent_listen_port,
  $log_file = $::zabbix::params::agent_log_file,
  $debug_level = $::zabbix::params::agent_debug_level,
  $enable_remote_commands = $::zabbix::params::agent_enable_remote_commands,
  $log_remote_commands = $::zabbix::params::agent_log_remote_commands,
  $start_agents = $::zabbix::params::agent_start_agents,
  $server_active = $::zabbix::params::agent_server_active,
  $refresh_active_checks = $::zabbix::params::agent_refresh_active_checks,
  $hostname = $::zabbix::params::agent_hostname,
  $hostname_item = $::zabbix::params::agent_hostname_item,
  $max_lines_per_second = $::zabbix::params::agent_max_lines_per_second,
  $allow_root = $::zabbix::params::agent_allow_root,
  $timeout = $::zabbix::params::agent_timeout,
  $include = $::zabbix::params::agent_include,
  $unsafe_user_parameters = $::zabbix::params::agent_unsafe_user_parameters,
  $firewall_defaults = $::zabbix::params::agent_enable_firewall,
  $firewall_allow_sources = $::zabbix::params::agent_firewall_allow_sources,
  $package = $::zabbix::params::agent_package,
  $service = $::zabbix::params::agent_service
) inherits ::zabbix::params {
  include zabbix::params
  include zabbix::agent::service

  if ! defined(Package[$package]) {
    package { $package :
      ensure      => 'present',
    }
  }

  file { '/etc/zabbix/zabbix_agentd.conf' :
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('zabbix/zabbix_agentd.conf.erb'),
    require => Package[$package],
  }->
  file { '/etc/sudoers.d/zabbix' :
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('zabbix/sudoers.erb')
  }~>
  Service[$service]

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => 10050,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
