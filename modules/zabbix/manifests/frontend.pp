# Class: zabbix::frontend
#
class zabbix::frontend (
  $apply_firewall_rules = $::zabbix::params::frontend_apply_firewall_rules,
  $config = $::zabbix::params::frontend_config,
  $config_template = $::zabbix::params::frontend_config_template,
  $db_driver = $::zabbix::params::frontend_db_driver,
  $db_host = $::zabbix::params::frontend_db_host,
  $db_name = $::zabbix::params::frontend_db_name,
  $db_password = $::zabbix::params::frontend_db_password,
  $db_port = $::zabbix::params::frontend_db_port,
  $db_schema = $::zabbix::params::frontend_db_schema,
  $db_user = $::zabbix::params::frontend_db_user,
  $firewall_allow_sources = $::zabbix::params::frontend_firewall_allow_sources,
  $image_format_default = $::zabbix::params::frontend_image_format_default,
  $install_ping_handler = $::zabbix::params::frontend_install_ping_handler,
  $nginx_config_template = $::zabbix::params::frontend_nginx_config_template,
  $package = $::zabbix::params::frontend_package,
  $ping_handler_template = $::zabbix::params::frontend_ping_handler_template,
  $service_fqdn = $::zabbix::params::frontend_service_fqdn,
  $zabbix_server = $::zabbix::params::frontend_zabbix_server,
  $zabbix_server_name = $::zabbix::params::frontend_zabbix_server_name,
  $zabbix_server_port = $::zabbix::params::frontend_zabbix_server_port,
) inherits ::zabbix::params {
  include nginx
  include nginx::service

  package { $package :
    ensure  => 'present',
    require => Class['nginx'],
  }

  if (!defined(Package['php5-fpm'])) {
    package { 'php5-fpm' :
      ensure => 'present',
    }
  }

  if (!defined(Package['php5-mysql'])) {
    package { 'php5-mysql' :
      ensure  => 'present',
      require => Package['php5-fpm']
    }
  }

  file { '/etc/nginx/sites-available/zabbix-server.conf' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($nginx_config_template),
    require => Class['nginx'],
  }->
  file { '/etc/nginx/sites-enabled/zabbix-server.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/zabbix-server.conf',
  }->
  service { 'php5-fpm' :
    ensure  => 'running',
    require => [
      Package['php5-fpm'],
      Package['php5-mysql'],
    ]
  }~>
  Service['nginx']

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => 80,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }

  file { $config :
    ensure  => 'present',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0600',
    content => template($config_template),
    require => Package[$package],
  }

  if ($install_ping_handler) {
    file { '/usr/share/zabbix/ping.php' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template($ping_handler_template),
    }
  }

  file { '/usr/share/zabbix/setup.php' :
    ensure => 'absent',
  }
}
