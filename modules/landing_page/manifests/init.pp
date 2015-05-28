# Class: landing_page
#
class landing_page (
  $app_user               = $::landing_page::params::app_user,
  $apply_firewall_rules   = $::landing_page::params::apply_firewall_rules,
  $apps                   = $::landing_page::params::apps,
  $config                 = $::landing_page::params::config,
  $config_template        = $::landing_page::params::config_template,
  $database_engine        = $::landing_page::params::database_engine,
  $database_host          = $::landing_page::params::database_host,
  $database_name          = $::landing_page::params::database_name,
  $database_password      = $::landing_page::params::database_password,
  $database_port          = $::landing_page::params::database_port,
  $database_user          = $::landing_page::params::database_user,
  $debug                  = $::landing_page::params::debug,
  $firewall_allow_sources = $::landing_page::params::firewall_allow_sources,
  $nginx_access_log       = $::landing_page::params::nginx_access_log,
  $nginx_error_log        = $::landing_page::params::nginx_error_log,
  $nginx_log_format       = $::landing_page::params::nginx_log_format,
  $nginx_server_aliases   = $::landing_page::params::nginx_server_aliases,
  $nginx_server_name      = $::landing_page::params::nginx_server_name,
  $package                = $::landing_page::params::package,
  $plugins_repository     = $::landing_page::params::plugins_repository,
  $ssl                    = $::landing_page::params::ssl,
  $ssl_cert_file          = $::landing_page::params::ssl_cert_file,
  $ssl_cert_file_contents = $::landing_page::params::ssl_cert_file_contents,
  $ssl_key_file           = $::landing_page::params::ssl_key_file,
  $ssl_key_file_contents  = $::landing_page::params::ssl_key_file_contents,
  $timezone               = $::landing_page::params::timezone,
  $uwsgi_socket           = $::landing_page::params::uwsgi_socket,
) inherits ::landing_page::params {

  # installing required $packages
  ensure_packages($package, {
    notify => Exec['landing_page-syncdb']
  })

  # creating application user and group
  user { $app_user :
    ensure => 'present',
  }

  # install mysql packages and apply mysql settings
  if($database_engine == 'django.db.backends.mysql') {
    class { '::mysql::server' :}
    class { '::mysql::client' :}
    class { '::mysql::server::account_security' :}
    ::mysql::db { $database_name :
      user     => $database_user,
      password => $database_password,
      host     => $database_host,
      grant    => ['all'],
      charset  => 'utf8',
      require  => [
        Class['::mysql::server'],
        Class['::mysql::server::account_security'],
      ],
    }
  } else {
    fail { "Engine ${database_engine} is not supported yet" :}
  }

  # /usr/share/landing_page/release/settings.py
  # landing_page main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0600',
    owner   => $app_user,
    group   => $app_user,
    content => template($config_template),
    require => [
      User[$app_user],
      Package[$package],
      ::Mysql::Db[$database_name],
    ],
    notify  => [
      Service['uwsgi'],
      Exec['landing_page-migratedb'],
    ]
  }

  # creating database schema
  exec { 'landing_page-syncdb' :
    command     => '/usr/share/landing_page/manage.py syncdb --noinput',
    user        => $app_user,
    require     => File[$config],
    refreshonly => true,

  }

  # running migrations
  exec { 'landing_page-migratedb' :
    command     => '/usr/share/landing_page/manage.py migrate --all',
    user        => $app_user,
    require     => Exec['landing_page-syncdb'],
    refreshonly => true,
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  if ($ssl) {
    ::nginx::resource::vhost { 'release-http' :
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

    ::nginx::resource::vhost { 'release' :
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

    if $ssl_cert_file_contents != '' {
      file { $ssl_cert_file :
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $ssl_cert_file_contents,
        before  => ::Nginx::Resource::Vhost['release'],
      }
    }

    if $ssl_key_file_contents != '' {
      file { $ssl_key_file :
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => $ssl_key_file_contents,
        before  => ::Nginx::Resource::Vhost['release'],
      }
    }
  } else {
    ::nginx::resource::vhost { 'release' :
      ensure              => 'present',
      listen_port         => 80,
      server_name         => [$nginx_server_name],
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
  }

  if($nginx_server_aliases) {
    ::nginx::resource::vhost { 'landing-aliases' :
      ensure              => 'present',
      server_name         => $nginx_server_aliases,
      listen_port         => 80,
      www_root            => '/var/www',
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${nginx_server_name}\$request_uri",
      },
    }

    ::nginx::resource::vhost { 'landing-aliases-ssl' :
      ensure              => 'present',
      listen_port         => 443,
      ssl_port            => 443,
      server_name         => $nginx_server_aliases,
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
      www_root            => '/var/www',
      location_cfg_append => {
        return => "301 https://${nginx_server_name}\$request_uri",
      },
    }
  }

  ::nginx::resource::location { 'release-static' :
    ensure   => 'present',
    vhost    => 'release',
    location => '/static/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/landing_page',
  }

  ::uwsgi::application { 'landing_page' :
    plugins => 'python',
    uid     => $app_user,
    gid     => $app_user,
    socket  => $uwsgi_socket,
    chdir   => '/usr/share/landing_page',
    module  => 'release.wsgi',
    require => User[$app_user],
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => [80, 443],
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
