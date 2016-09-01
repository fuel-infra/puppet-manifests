# Class: fuel_stats::collector
#
# This class deploys annonymous statistics collector.
#
# Parameters:
#   [*analytics_ip*] - analitics service IP
#   [*auto_update*] - run github poller every 15 minutes
#   [*development*] - development deployment type
#   [*email_list*] - String, list of emails to send statistic
#   [*filtering_rules*] - collector filters hash
#   [*firewall_enable*] - enable embedded firewall rules
#   [*fuel_stats_repo*] - fuel_stats repository URL
#   [*http_port*] - port for HTTP connections
#   [*https_port*] - port for HTTPS connections
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_limit_conn*] - maximum connections limit
#   [*nginx_log_format*] - log file format
#   [*psql_db*] - PostgreSQL database name
#   [*psql_pass*] - PostgreSQL database password
#   [*psql_user*] - PostgreSQL database user
#   [*script_path*] - String, the path where the script is located
#   [*service_hostname*] - service hostname
#   [*ssl_cert_file*] - SSL certificate file path
#   [*ssl_cert_file_contents*] - SSL certificate file contents
#   [*ssl_key_file*] - SSL key file path
#   [*ssl_key_file_contents*] - SSL key file contents
#
class fuel_stats::collector (
  $analytics_ip           = $fuel_stats::params::analytics_ip,
  $auto_update            = $fuel_stats::params::auto_update,
  $development            = $fuel_stats::params::development,
  $email_list             = 'root@localhost',
  $filtering_rules        = {},
  $firewall_enable        = $fuel_stats::params::firewall_enable,
  $fuel_stats_repo        = $fuel_stats::params::fuel_stats_repo,
  $http_port              = $fuel_stats::params::http_port,
  $https_port             = $fuel_stats::params::https_port,
  $nginx_access_log       = $fuel_stats::params::nginx_access_log,
  $nginx_error_log        = $fuel_stats::params::nginx_error_log,
  $nginx_limit_conn       = $fuel_stats::params::limit_conn,
  $nginx_log_format       = 'custom_collector',
  $psql_db                = $fuel_stats::params::psql_db,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_user              = $fuel_stats::params::psql_user,
  $script_path            = '/usr/bin/mn_geo',
  $service_hostname       = $::fqdn,
  $ssl_cert_file          = '/etc/ssl/analytic.crt',
  $ssl_cert_file_contents = '',
  $ssl_key_file           = '/etc/ssl/analytic.key',
  $ssl_key_file_contents  = '',
) inherits fuel_stats::params {
  if ( ! defined(Class['::fuel_stats::db']) ) {
    class { '::fuel_stats::db' :
      install_psql => true,
      psql_host    => $psql_host,
      psql_user    => $psql_user,
      psql_pass    => $psql_pass,
      psql_db      => $psql_db,
      analytics_ip => $analytics_ip,
    }
  }

  if ( ! defined(File[$ssl_cert_file]) and $ssl_cert_file_contents ) {
    file { $ssl_cert_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
    }
  }

  if ( ! defined(File[$ssl_key_file]) and $ssl_key_file_contents ) {
    file { $ssl_key_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
    }
  }

  file { '/etc/nginx/conf.d/log_format.conf' :
    source => 'puppet:///modules/fuel_stats/log_format.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Limiting access to analytics only from hosts
  if ($firewall_enable) {
    $firewall_rules = hiera_hash('fuel_stats::collector::firewall_rules', {})
  } else {
    $firewall_rules = {}
  }

  # application user
  user { 'collector' :
    ensure     => present,
    home       => '/var/www/collector',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  # filtering json
  file { '/etc/collector-filter.json' :
    ensure  => 'file',
    content => template('fuel_stats/collector-filter.json.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  # application settings
  file { '/etc/collector.py' :
    ensure  => 'file',
    content => template('fuel_stats/collect.py.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/etc/collector-filter.json'],
  }

  # Nginx configuration
  include ::nginx

  # rewrites, acl and limits configuration
  $_rewrite_to_https = { 'rewrite' => "^ https://${service_hostname}:${https_port}\$request_uri? permanent" }
  if ($nginx_limit_conn) {
    $_limit_conn = { 'limit_conn' => $nginx_limit_conn }
    $rewrite_to_https = merge($_rewrite_to_https, $_limit_conn)
    $location_cfg_append_firewall_limit = merge($firewall_rules, $_limit_conn)
  } else {
    $rewrite_to_https = $_rewrite_to_https
    $location_cfg_append_firewall_limit = $firewall_rules
  }

  # vhost configuration
  ::nginx::resource::vhost { 'collector' :
    ensure              => 'present',
    listen_port         => $http_port,
    server_name         => [$::fqdn],
    uwsgi               => '127.0.0.1:7932',
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => $location_cfg_append_firewall_limit,
  }

  # enable ssl
  if ( defined(File[$ssl_cert_file]) and defined(File[$ssl_key_file]) ) {
    Nginx::Resource::Vhost <| title == 'collector' |>  {
      listen_port => $https_port,
      ssl         => true,
      ssl_cert    => $ssl_cert_file,
      ssl_key     => $ssl_key_file,
      ssl_port    => $https_port,
      require     => [
        File[$ssl_cert_file],
        File[$ssl_key_file],
      ],
    }
    ::nginx::resource::vhost { 'collector-redirect' :
      ensure              => 'present',
      listen_port         => $http_port,
      www_root            => '/var/www',
      server_name         => [$::fqdn],
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => $rewrite_to_https,
    }
  }

  package { 'python-logparser' :
    ensure => 'latest',
  }

  if ($development) {
    # development configuration
    fuel_stats::dev { 'collector':
      require => User['collector'],
    }
    # uwsgi configuration
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      env      => 'COLLECTOR_SETTINGS=/etc/collector.py',
      chdir    => '/var/www/collector/collector',
      module   => 'collector.api.app_test',
      callable => 'app',
      require  => [
        File['/etc/collector.py'],
        File['/var/log/fuel-stats'],
        Fuel_stats::Dev['collector'],
      ],
    }
    $src_path = '/var/www/collector/collector'
    exec { 'upgrade-collector-db' :
      command     => "${src_path}/manage_collector.py --mode prod db upgrade -d .",
      environment => 'COLLECTOR_SETTINGS=/etc/collector.py',
      cwd         => "${src_path}/collector/api/db/migrations",
      require     => [
        Fuel_stats::Dev['collector'],
        File['/etc/collector.py'],
        Class['::fuel_stats::db'],
      ]
    }
  } else {
    # production configuration
    package { 'fuel-stats-collector' :
      ensure  => 'installed',
      require => [
        File['/etc/collector.py'],
        Class['::fuel_stats::db'],
      ],
      notify  => Service['uwsgi'],
    }
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      env      => 'COLLECTOR_SETTINGS=/etc/collector.py',
      chdir    => '/usr/lib/python2.7/dist-packages',
      module   => 'collector.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/collector.py'],
        File['/var/log/fuel-stats'],
        User['collector'],
      ],
    }
  }

  if ( ! defined(File['/var/log/fuel-stats']) ) {
    file { '/var/log/fuel-stats' :
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
  }

  file { '/var/log/fuel-stats/collector.log' :
    ensure => 'present',
    mode   => '0644',
    owner  => 'collector',
    group  => 'collector',
  }

  file { '/var/lock/python-logparser' :
    ensure => 'directory',
    owner  => 'collector',
    group  => 'collector',
    mode   => '0644',
  }

  file { '/var/log/logparser' :
    ensure => 'directory',
    owner  => 'collector',
    group  => 'collector',
    mode   => '0644',
  }

  cron { 'python-logparser' :
    command  => "/usr/bin/flock -xn /var/lock/python-logparser/mn_geo.lock  /usr/bin/timeout -k10 600 ${script_path} -m `date --date=yesterday \+\%m` -l /var/log/nginx -e ${email_list} 2>&1 | tee -a /var/log/logparser/logparser.log",
    user     => 'root',
    hour     => '0',
    minute   => '1',
    monthday => '1',
    require  => [
      Package['python-logparser'],
      File['/var/lock/python-logparser'],
      File['/var/log/logparser'],
    ],
  }
}
