# Class: lpreports::webapp
#
# This class deploys webapp part of lpreports application.
#
# Parameters:
#   [*config*] - lpreports configuration file entries
#   [*config_path*] - String, path to the configuration settings.yaml
#   [*logdir*] - log directory of lpreports
#   [*managepy_path*] - path to lpreports manage.py file
#   [*nginx_server_name*] - FQDN of service
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*package*] - String, package name(could contain or not contain version)
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
  $config_path              = '/etc/lpreports/settings.yaml',
  $logdir                   = '/var/log/lpreports',
  $managepy_path            = '/usr/bin/lpreports',
  $nginx_server_name        = $::fqdn,
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = undef,
  $package                  = 'python-lpreports',
  $reports                  = {},
  $review_filters           = {},
  $ssl_certificate          = '/etc/ssl/certs/lpreports.crt',
  $ssl_certificate_contents = undef,
  $ssl_key                  = '/etc/ssl/private/lpreports.key',
  $ssl_key_contents         = undef,
  $teams                    = {},
) {
  include ::nginx
  package { $package :
    ensure => 'latest',
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

  file { $config_path :
    ensure  => 'present',
    owner   => 'lpreports',
    group   => 'lpreports',
    mode    => '0400',
    content => inline_template('<%= YAML.dump(@config) %>'),
    require => Package[$package],
  }

  uwsgi::application { 'lpreports' :
    plugins   => 'python',
    module    => 'lpreports.wsgi',
    callable  => 'app',
    master    => true,
    lazy_apps => true,
    workers   => $::processorcount,
    socket    => '127.0.0.1:6776',
    vacuum    => true,
    uid       => 'lpreports',
    gid       => 'lpreports',
    chdir     => '/',
    require   => [
      User['lpreports'],
      Package[$package],
      File[$logdir],
    ],
    subscribe => [
      Package[$package],
      File[$config_path]
    ]
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
      Package[$package],
    ],
  }

  ::nginx::resource::location { 'static' :
    ensure   => 'present',
    vhost    => 'lpreports',
    ssl      => true,
    ssl_only => true,
    location => '/static/',
    www_root => '/usr/share/lpreports',
  }

  file { '/var/lock/lpreports' :
    ensure => 'directory',
    owner  => 'lpreports',
    group  => 'lpreports',
    mode   => '0644',
  }

  cron { 'lpreports-syncdb' :
    command => "/usr/bin/flock -xn /var/lock/lpreports/syncdb.lock /usr/bin/timeout -k10 240 ${managepy_path} syncdb >> ${logdir}/syncdb.log 2>&1",
    user    => 'lpreports',
    minute  => '*/10',
    require => [
      Package[$package],
      File[$logdir],
      File['/var/lock/lpreports'],
    ],
  }

  cron { 'lpreports-collect-assignees' :
    command => "/usr/bin/flock -xn /var/lock/lpreports/collect-assignees.lock /usr/bin/timeout -k10 60 ${managepy_path} collect-assignees >> ${logdir}/collect-assignees.log 2>&1",
    user    => 'lpreports',
    minute  => '*/1',
    require => [
      Package[$package],
      File[$logdir],
      File['/var/lock/lpreports'],
    ],
  }

  cron { 'lpreports-cleanup-db' :
    command => "/usr/bin/flock -xn /var/lock/lpreports/cleanup-db.lock /usr/bin/timeout -k10 8400 ${managepy_path} cleanup-db >> ${logdir}/cleanup-db.log 2>&1",
    user    => 'lpreports',
    hour    => '*/6',
    minute  => '24',
    require => [
      Package[$package],
      File[$logdir],
      File['/var/lock/lpreports'],
    ],
  }

  cron { 'lpreports-sync-cve' :
    command => "/usr/bin/flock -xn /var/lock/lpreports/sync-cve.lock /usr/bin/timeout -k10 60 ${managepy_path} sync-cve >> ${logdir}/sync_cve.log 2>&1",
    user    => 'lpreports',
    hour    => '*/6',
    minute  => '36',
    require => [
      Package[$package],
      File[$logdir],
      File['/var/lock/lpreports'],
    ],
  }

  cron { 'lpreports-sync-milestones' :
    command => "/usr/bin/flock -xn /var/lock/lpreports/sync-milestones.lock /usr/bin/timeout -k10810 10800 ${managepy_path} sync-milestones >> ${logdir}/sync_milestones.log 2>&1",
    user    => 'lpreports',
    hour    => '*',
    minute  => '*/30',
    require => [
      Package[$package],
      File[$logdir],
      File['/var/lock/lpreports'],
    ],
  }
}
