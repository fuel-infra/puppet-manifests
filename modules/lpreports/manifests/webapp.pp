# Class: lpreports::webapp
#
# This class deploys webapp part of lpreports application.
#
# Parameters:
#   [*config*] - lpreports configuration file entries
#   [*logdir*] - log directory of lpreports
#   [*managepy_path*] - path to lpreports manage.py file
#   [*nginx_server_name*] - FQDN of service
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*reports*] - reports configuration file entries
#   [*review_filters*] - reports configuration file entries
#   [*ssl_certificate*] - ssl certificate file path
#   [*ssl_certificate_contents*] - ssl certificate file contents
#   [*ssl_key*] - ssl key file path
#   [*ssl_key_contents*] - ssl key file contents
#   [*teams*] - team configuration file entries
#
class lpreports::webapp (
  $config                   = {},
  $logdir                   = '/var/log/lpreports',
  $managepy_path            = '/usr/lib/python2.7/dist-packages/lpreports/manage.py',
  $nginx_server_name        = $::fqdn,
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = undef,
  $reports                  = {},
  $review_filters           = {},
  $ssl_certificate          = '/etc/ssl/certs/lpreports.crt',
  $ssl_certificate_contents = undef,
  $ssl_key                  = '/etc/ssl/private/lpreports.key',
  $ssl_key_contents         = undef,
  $teams                    = {},
) {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }
  package { 'python-lp-reports' :
    ensure => 'present',
  }

  user { 'lpreports' :
    ensure     => 'present',
    shell      => '/bin/false',
    home       => '/var/lib/lpreports',
    managehome => true,
    system     => true
  }

  file { $logdir :
    ensure => 'directory',
    owner  => 'lpreports',
    group  => 'lpreports',
    mode   => '0700',
  }

  file { $ssl_certificate :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_certificate_contents,
  }

  file { $ssl_key :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_key_contents,
  }

  file { '/etc/lpreports/review.json' :
    ensure  => 'present',
    owner   => 'lpreports',
    group   => 'lpreports',
    mode    => '0400',
    content => template('lpreports/review.json.erb'),
    require => Package['python-lp-reports'],
  }

  file { '/etc/lpreports/lpreports.conf' :
    ensure  => 'present',
    owner   => 'lpreports',
    group   => 'lpreports',
    mode    => '0400',
    content => template('lpreports/lpreports.conf.erb'),
    require => Package['python-lp-reports'],
  }

  file { '/etc/lpreports/teams.yaml' :
    ensure  => 'present',
    owner   => 'lpreports',
    group   => 'lpreports',
    mode    => '0400',
    content => template('lpreports/teams.yaml.erb'),
    require => Package['python-lp-reports'],
  }

  file { '/etc/lpreports/reports.yaml' :
    ensure  => 'present',
    owner   => 'lpreports',
    group   => 'lpreports',
    mode    => '0400',
    content => template('lpreports/reports.yaml.erb'),
    require => Package['python-lp-reports'],
  }

  uwsgi::application { 'lpreports' :
    plugins  => 'python',
    module   => 'lpreports.wsgi',
    callable => 'app',
    master   => true,
    workers  => $::processorcount,
    socket   => '127.0.0.1:6776',
    vacuum   => true,
    uid      => 'lpreports',
    gid      => 'lpreports',
    require  => [
      User['lpreports'],
      Package['python-lp-reports'],
      File[$logdir],
    ],
  }

  ::nginx::resource::vhost { 'lpreports-http' :
    ensure              => 'present',
    server_name         => [$nginx_server_name],
    listen_port         => 80,
    www_root            => '/var/www',
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      return => "301 https://${nginx_server_name}\$request_uri",
    },
  }

  ::nginx::resource::vhost { 'lpreports' :
    ensure              => 'present',
    listen_port         => 443,
    ssl_port            => 443,
    server_name         => [$nginx_server_name],
    ssl                 => true,
    ssl_cert            => $ssl_certificate,
    ssl_key             => $ssl_key,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    uwsgi               => '127.0.0.1:6776',
    location_cfg_append => {
      uwsgi_connect_timeout  => '3m',
      uwsgi_read_timeout     => '3m',
      uwsgi_send_timeout     => '3m',
      uwsgi_intercept_errors => 'on',
    },
    require             => [
      File[$ssl_certificate],
      File[$ssl_key],
      Package['python-lp-reports'],
    ],
  }

  ::nginx::resource::location { 'static' :
    ensure   => 'present',
    vhost    => 'lpreports',
    ssl      => true,
    ssl_only => true,
    location => '/static/',
    www_root => '/usr/lib/python2.7/dist-packages/lpreports',
  }

  cron { 'lpreports-syncdb' :
    command => "${managepy_path} syncdb >> ${logdir}/syncdb.log 2>&1",
    user    => 'lpreports',
    minute  => '*/10',
    require => [
      Package['python-lp-reports'],
      File[$logdir],
    ],
  }

  cron { 'lpreports-collect-assignees' :
    command => "${managepy_path} collect-assignees >> ${logdir}/collect-assignees.log 2>&1",
    user    => 'lpreports',
    minute  => '*/1',
    require => [
      Package['python-lp-reports'],
      File[$logdir],
    ],
  }

  cron { 'lpreports-cleanup-db' :
    command => "${managepy_path} cleanup-db >> ${logdir}/cleanup-db.log 2>&1",
    user    => 'lpreports',
    hour    => '22',
    minute  => '0',
    require => [
      Package['python-lp-reports'],
      File[$logdir],
    ],
  }
}
