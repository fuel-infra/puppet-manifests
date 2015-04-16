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

  if($database_engine == 'django.db.backends.mysql') {
    ensure_packages('python-mysqldb')
  }

  file { $config :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($config_template),
    require => Package[$package],
    notify  => [
      Exec['errata_base-syncdb'],
      Exec['errata_base-migratedb'],
    ],
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
      uwsgi_connect_timeout => '3m',
      uwsgi_read_timeout    => '3m',
      uwsgi_send_timeout    => '3m',
    }
  }

  ::nginx::resource::location { 'errata-static' :
    ensure   => 'present',
    vhost    => 'errata',
    location => '/static/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/errata_base',
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

  user { $user :
    ensure     => 'present',
    system     => true,
    managehome => true,
    home       => "/var/lib/${user}",
    shell      => '/usr/sbin/nologin',
  }

  ::uwsgi::application { 'errata_base' :
    plugins => 'python',
    uid     => $user,
    gid     => $group,
    socket  => $uwsgi_socket,
    chdir   => '/usr/share/errata_base',
    module  => 'errata_base.wsgi',
    require => [
      User[$user],
      Package['python-mysqldb'],
    ]
  }

  exec { 'errata_base-syncdb' :
    command     => '/usr/share/errata_base/manage.py syncdb --noinput',
    user        => $user,
    require     => [
      File[$config],
      User[$user],
    ],
    refreshonly => true,
  }

  exec { 'errata_base-migratedb' :
    command     => '/usr/share/errata_base/manage.py migrate --all',
    user        => $user,
    require     => [
      Exec['errata_base-syncdb'],
      User[$user],
    ],
    refreshonly => true,
  }
}
