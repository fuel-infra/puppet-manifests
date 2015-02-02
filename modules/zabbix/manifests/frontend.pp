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
  $nginx_access_log = $::zabbix::params::frontend_nginx_access_log,
  $nginx_error_log = $::zabbix::params::frontend_nginx_error_log,
  $nginx_log_format = $::zabbix::params::frontend_nginx_log_format,
  $package = $::zabbix::params::frontend_package,
  $ping_handler_template = $::zabbix::params::frontend_ping_handler_template,
  $service_fqdn = $::zabbix::params::frontend_service_fqdn,
  $zabbix_server = $::zabbix::params::frontend_zabbix_server,
  $zabbix_server_name = $::zabbix::params::frontend_zabbix_server_name,
  $zabbix_server_port = $::zabbix::params::frontend_zabbix_server_port,
) inherits ::zabbix::params {
  include nginx
  include nginx::service

  include php::fpm::daemon

  if (!defined(Class['nginx'])) {
    class { '::nginx' :}
  }
  ::nginx::resource::vhost { 'zabbix-server' :
    ensure               => 'present',
    listen_port          => 80,
    server_name          => [$service_fqdn, $::fqdn],
    access_log           => $nginx_access_log,
    error_log            => $nginx_error_log,
    format_log           => $nginx_log_format,
    use_default_location => false,
  }

  ::nginx::resource::location { 'zabbix-server-static' :
    vhost    => 'zabbix-server',
    location => '/',
    www_root => '/usr/share/zabbix',
  }

  ::nginx::resource::location { 'zabbix-server-php' :
    vhost    => 'zabbix-server',
    location => '~ \.php$',
    fastcgi  => '127.0.0.1:9000',
    www_root => '/usr/share/zabbix',
  }

  ::php::fpm::conf { 'www':
    listen    => '127.0.0.1:9000',
    user      => 'www-data',
    php_value => {
      post_max_size      => 16M,
      max_execution_time => 300,
      max_input_time     => 300,
      'date.timezone'    => UTC,
      'cgi.fix_pathinfo' => 1,
    },
    require   => Class['::nginx'],
  }

  ::php::module { [ 'mysql', 'ldap', 'gd' ]: }

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

  if (!defined(Package[$package])) {
    package { $package :
      ensure  => 'present',
      require => [
        Class['::nginx'],
        Class['::php::fpm::daemon'],
        Php::Module['mysql', 'ldap', 'gd'],
      ],
    }
  }

  file { '/usr/share/zabbix/setup.php' :
    ensure => 'absent',
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => 80,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }

}
