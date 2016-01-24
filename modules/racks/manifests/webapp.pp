# Class: racks::webapp
#
# This class deploys web application part of inventory application.
#
# Parameters:
#
#   [*config*] - configuration file path for application
#   [*database_engine*] - Django database engine to use
#   [*database_host*] - database host name
#   [*database_name*] - database name
#   [*database_password*] - database password
#   [*database_port*] - database port
#   [*database_user*] - database user name
#   [*debug*] - enable debug mode
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
  $config                = '/etc/racks/setting.py',
  $database_engine       = 'django.db.backends.mysql',
  $database_host         = '127.0.0.1',
  $database_name         = 'racks',
  $database_password     = 'racks',
  $database_port         = '3306',
  $database_user         = 'racks',
  $debug                 = False,
  $group                 = 'racks',
  $nginx_access_log      = '/var/log/nginx/access.log',
  $nginx_error_log       = '/var/log/nginx/error.log',
  $nginx_log_format      = 'proxy',
  $nginx_server_name     = $::fqdn,
  $package               = [
    'python-django-racks',
    'python-django-racks-importer-meta-all'
  ],
  $ssl_cert_file         = '/etc/ssl/certs/racks.crt',
  $ssl_cert_file_content = '',
  $ssl_key_file          = '/etc/ssl/private/racks.key',
  $ssl_key_file_content  = '',
  $user                  = 'racks',
  $uwsgi_socket          = '127.0.0.1:4689',
) {
  ensure_packages($package)

  django::application { 'racks' :}

  exec { 'racks-syncdb' :
    command     => '/usr/share/racks/webapp/manage.py syncdb --noinput',
    user        => $user,
    require     => Django::Application['racks'],
    refreshonly => true,
  }

  exec { 'racks-migratedb' :
    command     => '/usr/share/racks/webapp/manage.py migrate --all',
    user        => $user,
    require     => [
      Exec['racks-syncdb'],
    ],
    refreshonly => true,
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
    }
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
    www_root => '/usr/share/racks/webapp',
  }

  ::nginx::resource::location { 'racks-docs' :
    ensure   => 'present',
    vhost    => 'racks',
    location => '/docs/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/racks',
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
}
