# Class: zabbix::agent
#
# This class configures Zabbix Agent instance.
#
# Parameters:
#   [*allow_root*] - allow the agent to run as 'root' user
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*debug_level*] - set debug level of Zabbix Agent
#   [*enable_remote_commands*] - allow to run remote commands on host with Agent
#   [*firewall_allow_sources*] - sources allowed to connect to the service
#   [*hostname*] - unique, case sensitive hostname
#   [*hostname_item*] - Zabbix agent item used for getting host name
#   [*include*] - individual files or all files in a directory in the
#     configuration file
#   [*listen_address*] - IP addresses that the agent should listen on
#   [*listen_port*] - listen on this port for connections from the server
#   [*log_file*] - log file path
#   [*log_remote_commands*] - logging of executed shell commands as warnings
#   [*max_lines_per_second*] - maximum number of new lines the agent will send
#     per second to Zabbix server or proxy when processing 'log' and 'eventlog'
#     active checks
#   [*package*] - program package with Zabbix Agent
#   [*refresh_active_checks*] - how often list of active checks is refreshed (s)
#   [*server_active*] - IP:port (or hostname:port) of Zabbix server or Zabbix
#     proxy for active checks
#   [*service*] - name of system service for Zabbix Agent
#   [*start_agents*] - Number of pre-forked instances of zabbix_agentd that
#     process passive check
#   [*sudoers_template*] - template file for sudoers entries used by Zabbix
#   [*timeout*] - spend no more than Timeout seconds on processing
#   [*unsafe_user_parameters*] - allow all characters to be passed in arguments
#     to user-defined parameters
#   [*zabbix_server*] - IP addresses (or hostnames) of Zabbix servers
#
class zabbix::agent (
  $allow_root             = $::zabbix::params::agent_allow_root,
  $apply_firewall_rules   = $::zabbix::params::agent_apply_firewall_rules,
  $debug_level            = $::zabbix::params::agent_debug_level,
  $enable_remote_commands = $::zabbix::params::agent_enable_remote_commands,
  $firewall_allow_sources = $::zabbix::params::agent_firewall_allow_sources,
  $hostname               = $::zabbix::params::agent_hostname,
  $hostname_item          = $::zabbix::params::agent_hostname_item,
  $include                = $::zabbix::params::agent_include,
  $listen_address         = $::zabbix::params::agent_listen_address,
  $listen_port            = $::zabbix::params::agent_listen_port,
  $log_file               = $::zabbix::params::agent_log_file,
  $log_remote_commands    = $::zabbix::params::agent_log_remote_commands,
  $max_lines_per_second   = $::zabbix::params::agent_max_lines_per_second,
  $package                = $::zabbix::params::agent_package,
  $refresh_active_checks  = $::zabbix::params::agent_refresh_active_checks,
  $server_active          = $::zabbix::params::agent_server_active,
  $service                = $::zabbix::params::agent_service,
  $start_agents           = $::zabbix::params::agent_start_agents,
  $sudoers_template       = $::zabbix::params::agent_sudoers_template,
  $timeout                = $::zabbix::params::agent_timeout,
  $unsafe_user_parameters = $::zabbix::params::agent_unsafe_user_parameters,
  $zabbix_server          = $::zabbix::params::agent_zabbix_server,
) inherits ::zabbix::params {
  include zabbix::params
  include zabbix::agent::service

  if ! defined(Package[$package]) {
    package { $package :
      ensure      => 'present',
    }
  }

  file { '/etc/zabbix/zabbix_agentd.conf' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('zabbix/agent/zabbix_agentd.conf.erb'),
    require => Package[$package],
  }->
  file { '/etc/sudoers.d/zabbix' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template($sudoers_template)
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
