# Class: zabbix::params
#
class zabbix::params {
  #
  # Agent default configuration
  #
  $agent_allow_root = false
  $agent_apply_firewall_rules = false
  $agent_debug_level = 3
  $agent_enable_remote_commands = true
  $agent_firewall_allow_sources = {
    '1000 - zabbix connections allow' => {
      source => '127.0.0.1/32',
    }
  }
  $agent_hostname = $::fqdn
  $agent_hostname_item = $::fqdn
  $agent_include = '/etc/zabbix/zabbix_agentd.conf.d/'
  $agent_listen_address = '0.0.0.0'
  $agent_listen_port = 10050
  $agent_log_file = '/var/log/zabbix-agent/zabbix_agentd.log'
  $agent_log_remote_commands = true
  $agent_max_lines_per_second = 100
  $agent_package = 'zabbix-agent'
  $agent_refresh_active_checks = 120
  $agent_server_active = undef
  $agent_service = 'zabbix-agent'
  $agent_start_agents = 2
  $agent_timeout = 5
  $agent_unsafe_user_parameters = false
  $agent_zabbix_server = '127.0.0.1'

  #
  # Frontend default configuration
  #
  $frontend_apply_firewall_rules = false
  $frontend_config = '/etc/zabbix/zabbix.conf.php'
  $frontend_config_temlate = 'zabbix/frontend/zabbix.conf.php.erb'
  $frontend_config_template = 'zabbix/frontend/zabbix.conf.php.erb'
  $frontend_db_driver = 'MYSQL'
  $frontend_db_host = '127.0.0.1'
  $frontend_db_name = 'zabbix'
  $frontend_db_password = ''
  $frontend_db_port = 3306
  $frontend_db_schema = ''
  $frontend_db_socket = undef
  $frontend_db_user = 'zabbix'
  $frontend_firewall_allow_sources = {}
  $frontend_image_format_default = 'IMAGE_FORMAT_PNG'
  $frontend_install_ping_handler = false
  $frontend_nginx_config_template = 'zabbix/frontend/nginx.conf.erb'
  $frontend_package = 'zabbix-frontend-php'
  $frontend_ping_handler_template = 'zabbix/frontend/ping.php.erb'
  $frontend_service_fqdn = undef
  $frontend_zabbix_server = '127.0.0.1'
  $frontend_zabbix_server_name = $::fqdn
  $frontend_zabbix_server_port = '10051'

  #
  # Server default configuration
  #
  $server_alert_script_path = '/etc/zabbix/alert.d/'
  $server_allow_root = false
  $server_apply_firewall_rules = false
  $server_cache_size = floor($::memorysize_mb/64*1024*1024)
  $server_cache_update_frequency = 60
  $server_config = '/etc/zabbix/zabbix_server.conf'
  $server_config_template = 'zabbix/server/zabbix_server.conf.erb'
  $server_db_driver = 'mysql'
  $server_db_host = '127.0.0.1'
  $server_db_name = 'zabbix'
  $server_db_password = ''
  $server_db_port = 3306
  $server_db_socket = undef
  $server_db_user = 'zabbix'
  $server_debug_level = 3
  $server_firewall_allow_sources = {}
  $server_fping6_location = '/usr/bin/fping'
  $server_fping_location = '/usr/bin/fping6'
  $server_history_cache_size = floor($::memorysize_mb/128*1024*1024)
  $server_history_text_cache_size = floor($::memorysize_mb/128*1024*1024)
  $server_housekeeping_frequency = 1
  $server_install_frontend = false
  $server_install_ping_handler = false
  $server_listen_ip = '0.0.0.0'
  $server_listen_port = 10051
  $server_log_file = '/var/log/zabbix-server/zabbix_server.log'
  $server_log_slow_queries = true
  $server_max_housekeeper_delete = 500
  $server_node_id = 1
  $server_node_no_events = false
  $server_node_no_history = false
  $server_package = 'zabbix-server-mysql'
  $server_pid_file = '/var/run/zabbix/zabbix_server.pid'
  $server_service = 'zabbix-server'
  $server_start_db_syncers = 1
  $server_start_discoverers = 2
  $server_start_http_pollers = 2
  $server_start_ipmi_pollers = 2
  $server_start_java_pollers = 2
  $server_start_pingers = 2
  $server_start_pollers = 2
  $server_start_pollers_unreachable = 2
  $server_start_proxy_pollers = 2
  $server_start_snmp_trapper = 2
  $server_start_timers = 2
  $server_start_trappers = 2
  $server_start_vmware_collectors = 2
  $server_timeout = 5
  $server_tmp_dir = '/tmp'
  $server_trapper_timeout = 300
  $server_trend_cache_size = floor($::memorysize_mb/128*1024*1024)
  $server_unavailable_delay = 60
  $server_unreachable_delay = 15
  $server_unreachable_period = 45
  $server_value_cache_size = floor($::memorysize_mb/128*1024*1024)

  #
  # MySQL default configuration
  #
  $mysql_package = 'mysql-server'
  $mysql_root_password = ''
}
