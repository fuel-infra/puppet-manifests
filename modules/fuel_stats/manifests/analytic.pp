# Class: fuel_stats::analytic
#
# This class deploys anonymous statistics analytic instance.
#
# Parameters:
#   [*auto_update*] - run github poller every 15 minutes
#   [*development*] - development deployment type
#   [*elastic_http_port*] - Elasticsearch http port
#   [*elastic_listen_ip*] - Elasticsearch listening ip
#   [*elastic_tcp_port*] - Elasticsearch TCP port
#   [*firewall_enable*] - enable embedded firewall rules
#   [*fuel_stats_repo*] - fuel-stats repository URL
#   [*http_port*] - http listening port
#   [*https_port*] - https listening port
#   [*psql_db*] - PostgreSQL database name
#   [*psql_host*] - PostgreSQL host name
#   [*psql_pass*] - PostgreSQL database password
#   [*psql_user*] - PostgreSQL user name
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_error_path*] - error pages path
#   [*nginx_limit_conn*] - sets the shared memory zone and the maximum allowed
#       number of connections
#   [*nginx_log_format*] - log format
#   [*service_hostname*] - service hostname
#   [*ssl_cert_file*] - ssl certificate file path
#   [*ssl_cert_file_contents*] - ssl certificate file contents
#   [*ssl_key_file*] - ssl key file path
#   [*ssl_key_file_contents*] - ssl key file contents
#
class fuel_stats::analytic (
  $auto_update            = $fuel_stats::params::auto_update,
  $development            = $fuel_stats::params::development,
  $elastic_http_port      = '9200',
  $elastic_listen_ip      = '127.0.0.1',
  $elastic_tcp_port       = '9300',
  $firewall_enable        = $fuel_stats::params::firewall_enable,
  $fuel_stats_repo        = 'https://github.com/openstack/fuel-stats/',
  $http_port              = $fuel_stats::params::http_port,
  $https_port             = $fuel_stats::params::https_port,
  $psql_db                = $fuel_stats::params::psql_db,
  $psql_host              = $fuel_stats::params::psql_host,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_user              = $fuel_stats::params::psql_user,
  $nginx_access_log       = $fuel_stats::params::nginx_access_log,
  $nginx_error_log        = $fuel_stats::params::nginx_error_log,
  $nginx_error_path       = 'fuel-infra',
  $nginx_limit_conn       = $fuel_stats::params::limit_conn,
  $nginx_log_format       = 'proxy',
  $service_hostname       = $::fqdn,
  $ssl_cert_file          = '/etc/ssl/analytic.crt',
  $ssl_cert_file_contents = '',
  $ssl_key_file           = '/etc/ssl/analytic.key',
  $ssl_key_file_contents  = '',
) inherits fuel_stats::params {
  ensure_packages('error-pages')

  if ( ! defined(Class['::fuel_stats::db']) ) {
    class { '::fuel_stats::db' :
      install_psql => false,
      psql_host    => $psql_host,
      psql_user    => $psql_user,
      psql_pass    => $psql_pass,
      psql_db      => $psql_db,
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

  # Limiting access to analytics only from hosts
  if ($firewall_enable) {
    $firewall_rules = hiera_hash('fuel_stats::analytic::firewall_rules', {})
  } else {
    $firewall_rules = {}
  }

  # application user
  user { 'analytics' :
    ensure     => present,
    home       => '/var/www/analytics',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  # application settings
  file { '/etc/analytics.py' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_stats/analytics.py.erb'),
  }

  if ($development) {
    $www_root = '/var/www/analytics/analytics/static'
  } else {
    $www_root = '/usr/share/fuel-stats-static/static'
  }

  # Nginx configuration
  if ( ! defined(Class['::nginx']) ) {
    include ::nginx
  }

  # rewrites, acl and limits configuration
  $_rewrite_to_https = { 'rewrite' => "^ https://${service_hostname}:${https_port}\$request_uri? permanent" }
  $_error_pages = {
    'error_page 403'         => "/${nginx_error_path}/403.html",
    'error_page 404'         => "/${nginx_error_path}/404.html",
    'error_page 500 502 504' => "/${nginx_error_path}/5xx.html",
  }
  if ($nginx_limit_conn) {
    $_limit_conn = { 'limit_conn' => $nginx_limit_conn }
    $rewrite_to_https = merge($_rewrite_to_https, $_limit_conn)
    $location_cfg_append_firewall_limit = merge($firewall_rules, $_limit_conn, $_error_pages)
  } else {
    $rewrite_to_https = $_rewrite_to_https
    $location_cfg_append_firewall_limit = merge($firewall_rules, $_error_pages)
  }

  # vhost configuration
  ::nginx::resource::vhost { 'analytics' :
    ensure              => 'present',
    listen_port         => $http_port,
    server_name         => [$::fqdn],
    www_root            => $www_root,
    location_cfg_append => $location_cfg_append_firewall_limit,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
  }

  # enable ssl
  if ( defined(File[$ssl_cert_file]) and defined(File[$ssl_key_file]) )  {
    $ssl = true
    Nginx::Resource::Vhost <| title == 'analytics' |> {
      listen_port => $https_port,
      ssl         => $ssl,
      ssl_cert    => $ssl_cert_file,
      ssl_key     => $ssl_key_file,
      ssl_port    => $https_port,
      require     => [
        File[$ssl_cert_file],
        File[$ssl_key_file],
      ],
    }
    ::nginx::resource::vhost { 'analytics-redirect' :
      ensure              => 'present',
      listen_port         => $http_port,
      www_root            => $www_root,
      server_name         => [$::fqdn],
      location_cfg_append => $rewrite_to_https,
    }
  }

  # error pages for analytics
  ::nginx::resource::location { 'analytics-error-pages' :
    ensure   => 'present',
    vhost    => 'analytics',
    location => '~ ^\/(mirantis|fuel-infra)\/(403|404|5xx)\.html$',
    ssl      => $ssl,
    ssl_only => $ssl,
    www_root => '/usr/share/error_pages',
    require  => Package['error-pages'],
  }

  ::nginx::resource::location { 'analytics-exporter' :
    ensure              => 'present',
    vhost               => 'analytics',
    location            => '/api',
    ssl                 => $ssl,
    ssl_only            => $ssl,
    uwsgi               => '127.0.0.1:7935',
    location_cfg_append => $location_cfg_append_firewall_limit,
  }

  ::nginx::resource::location { 'analytics-elastic' :
    ensure              => 'present',
    vhost               => 'analytics',
    location            => '~ ^(/fuel)?(/[0-9A-Za-z_]+)?/(_count|_search)',
    ssl                 => $ssl,
    ssl_only            => $ssl,
    proxy               => 'http://127.0.0.1:9200',
    location_cfg_append => $location_cfg_append_firewall_limit,
  }

  if ($development) {
    # development configuration
    fuel_stats::dev { 'analytics':
      require => User['analytics'],
    }
    uwsgi::application { 'analytics':
      plugins  => 'python',
      uid      => 'analytics',
      gid      => 'analytics',
      socket   => '127.0.0.1:7935',
      env      => 'ANALYTICS_SETTINGS=/etc/analytics.py',
      chdir    => '/var/www/analytics/analytics',
      module   => 'fuel_analytics.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/analytics.py'],
        File['/var/log/fuel-stats/analytics.log'],
        User['analytics'],
        Fuel_stats::Dev['analytics'],
      ],
    }
  } else {
    # production configuration
    package { 'fuel-stats-static' :
      ensure => 'installed',
    }
    package { 'fuel-stats-analytics' :
      ensure => 'installed',
      notify => Service['uwsgi'],
    }
    uwsgi::application { 'analytics':
      plugins  => 'python',
      uid      => 'analytics',
      gid      => 'analytics',
      socket   => '127.0.0.1:7935',
      env      => 'ANALYTICS_SETTINGS=/etc/analytics.py',
      chdir    => '/usr/lib/python2.7/dist-packages',
      module   => 'fuel_analytics.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/analytics.py'],
        File['/var/log/fuel-stats/analytics.log'],
        User['analytics'],
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

  file { '/var/log/fuel-stats/analytics.log' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'analytics',
    group   => 'analytics',
    require => [
      User['analytics'],
      File['/var/log/fuel-stats'],
    ],
  }

  # To be removed
  class { '::elasticsearch' :
    manage_repo  => false,
    java_install => true,
    java_package => 'openjdk-7-jre-headless',
    config       => {
      'network.host'       => $elastic_listen_ip,
      'http.port'          => $elastic_http_port,
      'transport.tcp.port' => $elastic_tcp_port,
    },
    require      => Class['::apt'],
    notify       => Service['elasticsearch']
  }

  service { 'elasticsearch' :
    ensure  => 'running',
    enable  => true,
    require => Class['elasticsearch']
  }
}
