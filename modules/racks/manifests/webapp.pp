# Class: racks::webapp
#
# This class deploys web application part of inventory application.
#
# Parameters:
#   [*config*] - configuration data for application
#   Could contain the following options:
#
#     DCIM_URL: "http://dcim/"
#     DCIM_API: "http://dcim/api/v1/"
#     DCIM_USER: 'user'
#     DCIM_PASSWORD: 'password'
#     DCIM_SERVER_OWNER_ID: 3
#     DCIM_API_TIMEOUT: 1
#     ZABBIX_URL: 'http://localhost:80/'
#     ZABBIX_USER: 'user'
#     ZABBIX_PASSWORD: 'password'
#     SECRET_KEY: 'Test secret key'
#     DEBUG: True
#
#   [*config_path*] - configuration file path for application
#   [*group*] - group used to install application
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*nginx_server_name*] - service host name
#   [*package*] - required python packages
#   [*ssl_cert_file*] - ssl certificate file path
#   [*ssl_cert_file_content*] - ssl certificate file contents
#   [*ssl_key_file*] - ssl key file path
#   [*ssl_key_file_content*] - ssl key file contents
#   [*user*] - user used to install application
#   [*uwsgi_socket*] - uwsgi socket listening address
#
class racks::webapp (
  $config                = {},
  $config_path           = '/etc/racks/settings.yaml',
  $group                 = 'racks',
  $nginx_access_log      = '/var/log/nginx/access.log',
  $nginx_error_log       = '/var/log/nginx/error.log',
  $nginx_log_format      = undef,
  $nginx_server_name     = $::fqdn,
  $package               = ['python-django-racks', 'python-django-racks-doc'],
  $ssl_cert_file         = '/etc/ssl/certs/racks.crt',
  $ssl_cert_file_content = '',
  $ssl_key_file          = '/etc/ssl/private/racks.key',
  $ssl_key_file_content  = '',
  $user                  = 'racks',
  $uwsgi_socket          = '127.0.0.1:4689',
) {
  class { 'uwsgi' :}

  user { $user :
    ensure     => 'present',
    managehome => true,
    home       => "/var/lib/${user}",
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  package { $package :
    ensure => 'latest',
    notify => [
      Uwsgi::Application['racks'],
      Exec['racks-migrate']
    ]
  }

  file { $config_path :
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => '0400',
    content => inline_template("<%= require 'yaml' ; YAML.dump(@config) %>"),
    require => [
      Package[$package],
      User[$user],
    ],
    notify  => Uwsgi::Application['racks'],
  }

  exec { 'racks-migrate' :
    command => '/usr/bin/racks migrate',
    user    => $user,
    require => [
      User[$user],
    ],
  }

  ::nginx::resource::vhost { 'racks-http' :
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

  ::nginx::resource::vhost { 'racks' :
    ensure              => 'present',
    listen_port         => 443,
    ssl_port            => 443,
    server_name         => [$nginx_server_name],
    ssl                 => true,
    ssl_cert            => $ssl_cert_file,
    ssl_key             => $ssl_key_file,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    uwsgi               => $uwsgi_socket,
    location_cfg_append => {
      uwsgi_connect_timeout    => '3m',
      uwsgi_read_timeout       => '3m',
      uwsgi_send_timeout       => '3m',
      uwsgi_intercept_errors   => 'on',
      'error_page 403'         => '/mirantis/403.html',
      'error_page 404'         => '/mirantis/404.html',
      'error_page 500 502 504' => '/mirantis/5xx.html',
    },
    vhost_cfg_append    => {
      'add_header' => [
        "'Strict-Transport-Security' 'max-age=2592000'",
        '\'Content-Security-Policy\' "default-src \'self\' \'unsafe-inline\' https://static.fuel-infra.org"'
      ],
    },
  }

  ::nginx::resource::location { 'racks-api' :
    ensure              => 'present',
    vhost               => 'racks',
    location            => '/api/',
    ssl                 => true,
    ssl_only            => true,
    uwsgi               => $uwsgi_socket,
    location_cfg_append => {
      uwsgi_connect_timeout => '3m',
      uwsgi_read_timeout    => '3m',
      uwsgi_send_timeout    => '3m',
    },
  }

  ::nginx::resource::location { 'racks-static' :
    ensure   => 'present',
    vhost    => 'racks',
    location => '/static/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/racks',
  }

  ::nginx::resource::location { 'racks-docs' :
    ensure   => 'present',
    vhost    => 'racks',
    location => '/docs/',
    ssl      => true,
    ssl_only => true,
    alias    => '/usr/share/doc/python-django-racks/html',
  }

  ::nginx::resource::location { 'racks-error-pages' :
    ensure   => 'present',
    vhost    => 'racks',
    location => '~ ^\/(mirantis|fuel-infra)\/(403|404|5xx)\.html$',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/error_pages',
  }

  if ($ssl_cert_file and $ssl_cert_file_content != '') {
    file { $ssl_cert_file :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_content,
    }
  }

  if ($ssl_key_file and $ssl_key_file_content != '') {
    file { $ssl_key_file :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_content,
    }
  }

  uwsgi::application { 'racks' :
    plugins   => 'python',
    workers   => $::processorcount,
    uid       => $user,
    gid       => $user,
    socket    => $uwsgi_socket,
    master    => true,
    vacuum    => true,
    module    => 'racks.wsgi',
    subscribe => [
      User[$user],
      File[$config_path],
      Package[$package],
    ],
  }
}
