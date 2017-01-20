# Class: ci_status::webapp
#
# This class deploys webapp part of ci_status application.
#
# Parameters:
#   [*config*] - ci_status configuration file entries
#   [*config_dir*] - string, path to the configuration directory
#   [*logdir*] - log directory of ci_status
#   [*managepy_path*] - path to ci_status manage.py file
#   [*nginx_server_name*] - FQDN of service
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*package*] - String, package name(could contain or not contain version)
#   [*ssl_certificate*] - ssl certificate file path
#   [*ssl_certificate_contents*] - ssl certificate file contents
#   [*ssl_key*] - ssl key file path
#   [*ssl_key_contents*] - ssl key file contents
#   [*user*] - user used to run application
#
class ci_status::webapp (
  $config                   = {},
  $config_dir              = '/etc/ci-status',
  $logdir                   = '/var/log/ci_status',
  $managepy_path            = '/usr/bin/ci_status',
  $nginx_server_name        = $::fqdn,
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = undef,
  $package                  = 'python-django-ci-status',
  $ssl_certificate          = '/etc/ssl/certs/ci_status.crt',
  $ssl_certificate_contents = undef,
  $ssl_key                  = '/etc/ssl/private/ci_status.key',
  $ssl_key_contents         = undef,
  $user                     = 'ci_status'
) {
  include ::nginx
  include ::supervisord

  $_requirements = [
    $package,
    'rabbitmq-server',
  ]

  ensure_packages($_requirements, {
    'ensure' => 'latest'
  })

  user { $user :
    ensure     => 'present',
    shell      => '/bin/false',
    home       => '/var/lib/ci_status',
    managehome => true,
    system     => true
  }

  file { $logdir :
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0700',
    require => User[$user],
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

  file { $config_dir :
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${config_dir}/settings.yaml" :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_template('<%= YAML.dump(@config) %>'),
    require => [
      Package[$_requirements],
      File[$config_dir],
    ]
  }

  exec { 'ci_status-syncdb' :
    command     => 'django-admin syncdb --noinput',
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => [
      Package[$_requirements],
      User[$user],
      File["${config_dir}/settings.yaml"],
    ]
  }

  exec { 'ci_status-migratedb' :
    command     => 'django-admin migrate',
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => Exec['ci_status-syncdb'],
    notify      => Service['uwsgi'],
  }

  uwsgi::application { 'ci_status' :
    plugins   => 'python',
    module    => 'ci_dashboard.wsgi',
    master    => true,
    lazy_apps => true,
    workers   => $::processorcount,
    socket    => '127.0.0.1:6776',
    vacuum    => true,
    uid       => $user,
    gid       => $user,
    chdir     => '/',
    env       => 'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    require   => [
      User[$user],
      Package[$package],
      File[$logdir],
    ],
    subscribe => [
      Package[$package],
      File[$config_dir]
    ]
  }

  ::nginx::resource::vhost { 'ci_status-http' :
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

  ::nginx::resource::vhost { 'ci_status' :
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
      Package[$_requirements],
    ],
  }

  ::nginx::resource::location { 'static' :
    ensure         => 'present',
    vhost          => 'ci_status',
    ssl            => true,
    ssl_only       => true,
    location       => '/static/',
    location_alias => '/usr/lib/python2.7/dist-packages/ci_dashboard/static/ci_dashboard/',
  }
}
