# Class: ci_status::webapp
#
# This class deploys webapp part of ci_status application.
#
# Parameters:
#   [*config*] - ci_status configuration (template) file entries
#   [*config_dir*] - string, path to the configuration directory
#   [*logdir*] - log directory of ci_status
#   [*managepy_path*] - path to ci_status manage.py file
#   [*nginx_server_name*] - FQDN of service
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*package*] - String, package name(could contain or not contain version)
#   [*settings*] - ci_status settings (django) file entries
#   [*ssl_certificate*] - ssl certificate file path
#   [*ssl_certificate_contents*] - ssl certificate file contents
#   [*ssl_key*] - ssl key file path
#   [*ssl_key_contents*] - ssl key file contents
#   [*user*] - user used to run application
#
class ci_status::webapp (
  $config                   = undef,
  $config_dir               = '/etc/ci-status',
  $logdir                   = '/var/log/ci_status',
  $managepy_path            = '/usr/bin/ci_status',
  $nginx_server_name        = $::fqdn,
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = undef,
  $package                  = 'python-django-ci-status',
  $settings                 = undef,
  $ssl_certificate          = '/etc/ssl/certs/ci_status.crt',
  $ssl_certificate_contents = undef,
  $ssl_key                  = '/etc/ssl/private/ci_status.key',
  $ssl_key_contents         = undef,
  $user                     = 'ci_status'
) {
  include ::nginx

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

  file { "${config_dir}/config.yaml" :
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

  file { "${config_dir}/settings.yaml" :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => inline_template('<%= YAML.dump(@settings) %>'),
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
    ],
    notify      => Service['uwsgi'],
  }

  exec { 'ci_status-migrate' :
    command     => 'django-admin migrate',
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => Exec['ci_status-syncdb'],
  }

  exec { 'ci_status-staff_group' :
    command     => 'django-admin staff_group',
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => Exec['ci_status-migrate'],
  }

  exec { 'ci_status-import_config' :
    command     => "django-admin import_config ${config_dir}/config.yaml",
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => Exec['ci_status-staff_group'],
  }

  exec { 'ci_status-update' :
    command     => 'django-admin update',
    environment => [
      'DJANGO_SETTINGS_MODULE=ci_dashboard.settings',
    ],
    user        => $user,
    require     => Exec['ci_status-import_config'],
  }

  class { 'supervisord':
    config_file    => '/etc/supervisor/supervisord.conf',
    config_include => '/etc/supervisor/conf.d',
  }

  supervisord::program { 'ci_status':
    command             => 'celery worker -A ci_dashboard -B --loglevel=INFO -s /var/lib/ci_status/celery-schedule',
    user                => 'ci_status',
    autostart           => true,
    autorestart         => true,
    program_environment => {
      'DJANGO_SETTINGS_MODULE' => 'ci_dashboard.settings',
    },
    require             => User[$user],
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
