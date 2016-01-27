# Class: zabbix::proxy
#
# This class deploys Zabbix Proxy daemon and configures it.
#
# Parameters:
#
#   [*allow_root*] - allow the agent to run as 'root' user
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*cache_size*] - size of configuration cache, in bytes
#   [*config*] - configuration file path
#   [*config_frequency*] - how often proxy retrieves configuration data from
#     Zabbix server in seconds
#   [*config_template*] - configuration file template
#   [*data_sender_frequency*] - Proxy will send collected data to the server
#     every N seconds
#   [*db_driver*] - database driver
#   [*db_host*] - database host
#   [*db_name*] - database name
#   [*db_password*] - database password
#   [*db_port*] - database port
#   [*db_socket*] - database socket
#   [*db_user*] - database user
#   [*debug_level*] - Zabbix proxy debug level
#   [*enable_snmp_bulk_requests*] - enable SNMP bulk requests
#   [*external_scripts*] - location of external scripts
#   [*firewall_allow_sources*] - sources allowed to connect to the service
#   [*fping6_location*] - path to fping6 file
#   [*fping_location*] - path to fping file
#   [*heartbeat_frequency*] - frequency of heartbeat messages in seconds
#   [*history_cache_size*] - size of history cache, in bytes
#   [*history_text_cache_size*] - size of text history cache, in bytes
#   [*hostname*] - unique, case sensitive Proxy name. Make sure the proxy name
#     is known to the server!
#   [*hostname_item*] - item used for setting Hostname if it is undefined (this
#     will be run on the proxy similarly as on an agent)
#   [*housekeeping_frequency*] - How often Zabbix will perform housekeeping
#     procedure (in hours).
#   [*include*] - include individual files or all files in a directory in the
#     configuration file
#   [*java_gateway*] - IP address (or hostname) of Zabbix Java gateway
#   [*java_gateway_port*] - port that Zabbix Java gateway listens on
#   [*listen_ip*] - IP addresses that the trapper should listen on
#   [*listen_port*] - listen port for trapper
#   [*load_module*] - module to load at proxy startup
#   [*load_module_path*] - full path to location of proxy modules
#   [*log_file*] - name of log file
#   [*log_file_size*] - maximum size of log file in MB
#   [*log_slow_queries*] - how long a database query may take before being
#     logged (in milliseconds).
#   [*package*] - package required to install Zabbix proxy
#   [*pid_file*] - pid file location
#   [*proxy_local_buffer*] -  proxy will keep data locally for N hours, even if
#     the data have already been synced with the server
#   [*proxy_mode*] - proxy operating mode:
#     0 - proxy in the active mode
#     1 - proxy in the passive mode
#   [*proxy_offline_buffer*] - proxy will keep data for N hours in case if no
#     connectivity with Zabbix server
#   [*server*] - IP address (or hostname) of Zabbix server
#   [*server_port*] - port of Zabbix trapper on Zabbix server
#   [*service*] - Zabbix proxy system service name
#   [*snmp_trapper_file*] - temporary file used for passing data from SNMP trap
#     daemon to the proxy
#   [*source_ip*] - source IP address for outgoing connections
#   [*ssh_key_location*] - location of public and private keys for SSH
#     checks and actions
#   [*start_db_syncers*] - number of pre-forked instances of DB Syncers
#   [*start_discoverers*] - number of pre-forked instances of discoverers
#   [*start_http_pollers*] - number of pre-forked instances of HTTP pollers
#   [*start_ipmi_pollers*] - number of pre-forked instances of IPMI pollers
#   [*start_java_pollers*] - number of pre-forked instances of Java pollers
#   [*start_pingers*] - number of pre-forked instances of ICMP pingers
#   [*start_pollers*] - number of pre-forked instances of pollers
#   [*start_pollers_unreachable*] - number of pre-forked instances of pollers
#     for unreachable hosts (including IPMI)
#   [*start_snmp_trapper*] - if set to 1, SNMP trapper process will be started
#   [*start_trappers*] - number of pre-forked instances of trappers
#   [*start_vmware_collectors*] - number of pre-forked vmware collector
#     instances
#   [*timeout*] - specifies how long we wait for agent, SNMP device or external
#     check (in seconds)
#   [*tmp_dir*] - temporary directory
#   [*trapper_timeout*] - specifies how many seconds trapper may spend
#     processing new data
#   [*unavailable_delay*] - how often host is checked for availability during
#     the unavailability period, in seconds
#   [*unreachable_delay*] - how often host is checked for availability during
#     the unreachability period, in seconds
#   [*unreachable_period*] - after how many seconds of unreachability treat a
#     host as unavailable
#   [*vmware_cache_size*] - shared memory size for storing VMware data
#   [*vmware_frequency*] - delay in seconds between data gathering from a single
#     VMware service
#
class zabbix::proxy (
  $allow_root                = $::zabbix::params::proxy_allow_root,
  $apply_firewall_rules      = $::zabbix::params::proxy_apply_firewall_rules,
  $cache_size                = $::zabbix::params::proxy_cache_size,
  $config                    = $::zabbix::params::proxy_config,
  $config_frequency          = $::zabbix::params::proxy_config_frequency,
  $config_template           = $::zabbix::params::proxy_config_template,
  $data_sender_frequency     = $::zabbix::params::proxy_data_sender_frequency,
  $db_driver                 = $::zabbix::params::proxy_db_driver,
  $db_host                   = $::zabbix::params::proxy_db_host,
  $db_name                   = $::zabbix::params::proxy_db_name,
  $db_password               = $::zabbix::params::proxy_db_password,
  $db_port                   = $::zabbix::params::proxy_db_port,
  $db_socket                 = $::zabbix::params::proxy_db_socket,
  $db_user                   = $::zabbix::params::proxy_db_user,
  $debug_level               = $::zabbix::params::proxy_debug_level,
  $enable_snmp_bulk_requests = $::zabbix::params::proxy_enable_snmp_bulk_requests,
  $external_scripts          = $::zabbix::params::proxy_external_scripts,
  $firewall_allow_sources    = $::zabbix::params::proxy_firewall_allow_sources,
  $fping6_location           = $::zabbix::params::proxy_fping6_location,
  $fping_location            = $::zabbix::params::proxy_fping_location,
  $heartbeat_frequency       = $::zabbix::params::proxy_heartbeat_frequency,
  $history_cache_size        = $::zabbix::params::proxy_history_cache_size,
  $history_text_cache_size   = $::zabbix::params::proxy_history_text_cache_size,
  $hostname                  = $::zabbix::params::proxy_hostname,
  $hostname_item             = $::zabbix::params::proxy_hostname_item,
  $housekeeping_frequency    = $::zabbix::params::proxy_housekeeping_frequency,
  $include                   = $::zabbix::params::proxy_include,
  $java_gateway              = $::zabbix::params::proxy_java_gateway,
  $java_gateway_port         = $::zabbix::params::proxy_java_gateway_port,
  $listen_ip                 = $::zabbix::params::proxy_listen_ip,
  $listen_port               = $::zabbix::params::proxy_listen_port,
  $load_module               = $::zabbix::params::proxy_load_module,
  $load_module_path          = $::zabbix::params::proxy_load_module_path,
  $log_file                  = $::zabbix::params::proxy_log_file,
  $log_file_size             = $::zabbix::params::proxy_log_file_size,
  $log_slow_queries          = $::zabbix::params::proxy_log_slow_queries,
  $package                   = $::zabbix::params::proxy_package,
  $pid_file                  = $::zabbix::params::proxy_pid_file,
  $proxy_local_buffer        = $::zabbix::params::proxy_local_buffer,
  $proxy_mode                = $::zabbix::params::proxy_mode,
  $proxy_offline_buffer      = $::zabbix::params::proxy_offline_buffer,
  $server                    = $::zabbox::params::proxy_server,
  $server_port               = $::zabbix::params::proxy_server_port,
  $service                   = $::zabbix::params::proxy_service,
  $snmp_trapper_file         = $::zabbix::params::proxy_snmp_trapper_file,
  $source_ip                 = $::zabbix::params::proxy_source_ip,
  $ssh_key_location          = $::zabbix::params::proxy_ssh_key_location,
  $start_db_syncers          = $::zabbix::params::proxy_start_db_syncers,
  $start_discoverers         = $::zabbix::params::proxy_start_discoverers,
  $start_http_pollers        = $::zabbix::params::proxy_start_http_pollers,
  $start_ipmi_pollers        = $::zabbix::params::proxy_start_ipmi_pollers,
  $start_java_pollers        = $::zabbix::params::proxy_start_java_pollers,
  $start_pingers             = $::zabbix::params::proxy_start_pingers,
  $start_pollers             = $::zabbix::params::proxy_start_pollers,
  $start_pollers_unreachable = $::zabbix::params::proxy_start_pollers_unreachable,
  $start_snmp_trapper        = $::zabbix::params::proxy_start_snmp_trapper,
  $start_trappers            = $::zabbix::params::proxy_start_trappers,
  $start_vmware_collectors   = $::zabbix::params::proxy_start_vmware_collectors,
  $timeout                   = $::zabbix::params::proxy_timeout,
  $tmp_dir                   = $::zabbix::params::proxy_tmp_dir,
  $trapper_timeout           = $::zabbix::params::proxy_trapper_timeout,
  $unavailable_delay         = $::zabbix::params::proxy_unavailable_delay,
  $unreachable_delay         = $::zabbix::params::proxy_unreachable_delay,
  $unreachable_period        = $::zabbix::params::proxy_unreachable_period,
  $vmware_cache_size         = $::zabbix::params::proxy_vmware_cache_size,
  $vmware_frequency          = $::zabbix::params::proxy_vmware_frequency,
) inherits ::zabbix::params {
  class { '::mysql::server' :
    users     => {
      'zabbix@localhost' => {
        password_hash => mysql_password($db_password),
      },
      'zabbix@127.0.0.1' => {
        password_hash => mysql_password($db_password),
      }
    },
    databases => {
      'zabbix' => {
        charset => 'utf8',
      }
    },
    grants    => {
      'zabbix@localhost/zabbix.*' => {
        options    => ['GRANT'],
        privileges => ['ALTER', 'CREATE', 'INDEX', 'SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        table      => 'zabbix.*',
        user       => 'zabbix@localhost',
      },
      'zabbix@127.0.0.1/zabbix.*' => {
        options    => ['GRANT'],
        privileges => ['ALTER', 'CREATE', 'INDEX', 'SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        table      => 'zabbix.*',
        user       => 'zabbix@127.0.0.1',
      }
    }
  }

  exec { 'import-zabbix-fixtures' :
    command  => "zcat /usr/share/zabbix-proxy-mysql/schema.sql.gz | \
    mysql -h'${db_host}' -u'${db_user}' -p'${db_password}' '${db_name}'",
    provider => 'shell',
    creates  => '/etc/zabbix/zabbix_proxy_installed.flag',
    require  => [Class['::mysql::server'], Package[$package]]
  }->
  exec { 'flag-installation-complete' :
    command  => 'touch /etc/zabbix/zabbix_proxy_installed.flag',
    provider => 'shell',
  }

  package { $package :
    ensure  => 'present',
    require => Class['::mysql::server']
  }

  file { $config :
    ensure  => 'present',
    owner   => 'zabbix',
    group   => 'zabbix',
    mode    => '0400',
    content => template($config_template),
    require => Package[$package],
    notify  => Service[$service],
  }

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Package[$package],
      File[$config],
    ]
  }

  if ($::osfamily == 'Debian') {
    file { '/etc/default/zabbix-proxy' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => template('zabbix/proxy/zabbix_proxy_defaults.erb'),
      before  => File[$config],
    }

    Service[$service] {
      provider => 'debian'
    }
  }
}
