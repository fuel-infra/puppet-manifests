# Class: errata_base
#
class errata::web (
  $config                = $::errata::params::config,
  $config_template       = $::errata::params::config_template,
  $database_engine       = $::errata::params::database_engine,
  $database_host         = $::errata::params::database_host,
  $database_name         = $::errata::params::database_name,
  $database_password     = $::errata::params::database_password,
  $database_port         = $::errata::params::database_port,
  $database_user         = $::errata::params::database_user,
  $debug                 = $::errata::params::debug,
  $group                 = $::errata::params::gid,
  $nginx_access_log      = $::errata::params::nginx_access_log,
  $nginx_error_log       = $::errata::params::nginx_error_log,
  $nginx_log_format      = $::errata::params::nginx_log_format,
  $nginx_server_name     = $::errata::params::nginx_server_name,
  $package               = $::errata::params::package,
  $ssl_cert_file         = $::errata::params::ssl_cert_file,
  $ssl_cert_file_content = $::errata::params::ssl_cert_file_content,
  $ssl_key_file          = $::errata::params::ssl_key_file,
  $ssl_key_file_content  = $::errata::params::ssl_key_file_content,
  $user                  = $::errata::params::uid,
  $uwsgi_socket          = $::errata::params::uwsgi_socket,
) inherits ::errata::params {
  ensure_packages($package)

  django::application { 'errata_base' :}

  exec { 'errata_base-syncdb' :
    command     => '/usr/share/errata_base/manage.py syncdb --noinput',
    user        => $user,
    require     => Django::Application['errata_base'],
    refreshonly => true,
  }

  exec { 'errata_base-migratedb' :
    command     => '/usr/share/errata_base/manage.py migrate --all',
    user        => $user,
    require     => [
      Exec['errata_base-syncdb'],
    ],
    refreshonly => true,
  }

  ::nginx::resource::vhost { 'errata-http' :
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

  ::nginx::resource::vhost { 'errata' :
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

  ::nginx::resource::location { 'errata-api' :
    ensure              => 'present',
    vhost               => 'errata',
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

  ::nginx::resource::location { 'errata-static' :
    ensure   => 'present',
    vhost    => 'errata',
    location => '/static/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/errata_base',
  }

  ::nginx::resource::location { 'errata-error-pages' :
    ensure   => 'present',
    vhost    => 'errata',
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
