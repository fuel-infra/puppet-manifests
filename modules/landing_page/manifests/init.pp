# Class: landing_page
#
# This class deploys instance of landing page Django application.
#
# Parameters:
#   [*app_user*] - user and group used to deploy instance
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*apps*] - applications to deploy
#   [*config*] - configuration file path
#   [*config_template*] - configuration file template
#   [*database_engine*] - database engine used by Django
#   [*database_host*] - database host name
#   [*database_name*] - database name
#   [*database_password*] - database password
#   [*database_port*] - database port
#   [*database_user*] - database user
#   [*debug*] - enable Django debug
#   [*firewall_allow_sources*] - allow connections from these sources
#   [*google_analytics_property_id*] - Google Analytics property_id
#   [*nginx_access_log*] - access log
#   [*nginx_error_log*] - error log
#   [*nginx_log_format*] - log format
#   [*nginx_server_aliases*] - server aliases
#   [*nginx_server_name*] - server primary name
#   [*package*] - packages required to install
#   [*plugins_repository*] - plugins repository URL
#   [*ssl*] - enable ssl port
#   [*ssl_cert_file*] - ssl certificate file path
#   [*ssl_cert_file_contents*] - ssl certificate file contents
#   [*ssl_key_file*] - ssl key file path
#   [*ssl_key_file_contents*] - ssl key file contents
#   [*timezone*] - timezone used in application
#   [*uwsgi_socket*] - uwsgi listening socket
#
class landing_page (
  $app_user                     = $::landing_page::params::app_user,
  $apply_firewall_rules         = $::landing_page::params::apply_firewall_rules,
  $apps                         = $::landing_page::params::apps,
  $config                       = $::landing_page::params::config,
  $config_template              = $::landing_page::params::config_template,
  $database_engine              = $::landing_page::params::database_engine,
  $database_host                = $::landing_page::params::database_host,
  $database_name                = $::landing_page::params::database_name,
  $database_password            = $::landing_page::params::database_password,
  $database_port                = $::landing_page::params::database_port,
  $database_user                = $::landing_page::params::database_user,
  $debug                        = $::landing_page::params::debug,
  $firewall_allow_sources       = $::landing_page::params::firewall_allow_sources,
  $google_analytics_property_id = $::landing_page::params::google_analytics_property_id,
  $nginx_access_log             = $::landing_page::params::nginx_access_log,
  $nginx_error_log              = $::landing_page::params::nginx_error_log,
  $nginx_log_format             = $::landing_page::params::nginx_log_format,
  $nginx_server_aliases         = $::landing_page::params::nginx_server_aliases,
  $nginx_server_name            = $::landing_page::params::nginx_server_name,
  $package                      = $::landing_page::params::package,
  $plugins_repository           = $::landing_page::params::plugins_repository,
  $ssl                          = $::landing_page::params::ssl,
  $ssl_cert_file                = $::landing_page::params::ssl_cert_file,
  $ssl_cert_file_contents       = $::landing_page::params::ssl_cert_file_contents,
  $ssl_key_file                 = $::landing_page::params::ssl_key_file,
  $ssl_key_file_contents        = $::landing_page::params::ssl_key_file_contents,
  $timezone                     = $::landing_page::params::timezone,
  $uwsgi_socket                 = $::landing_page::params::uwsgi_socket,
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
        uwsgi_connect_timeout    => '3m',
        uwsgi_read_timeout       => '3m',
        uwsgi_send_timeout       => '3m',
        uwsgi_intercept_errors   => 'on',
        'error_page 403'         => '/fuel-infra/403.html',
        'error_page 404'         => '/fuel-infra/404.html',
        'error_page 500 502 504' => '/fuel-infra/5xx.html',
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
        uwsgi_connect_timeout    => '3m',
        uwsgi_read_timeout       => '3m',
        uwsgi_send_timeout       => '3m',
        uwsgi_intercept_errors   => 'on',
        'error_page 403'         => '/fuel-infra/403.html',
        'error_page 404'         => '/fuel-infra/404.html',
        'error_page 500 502 504' => '/fuel-infra/5xx.html',
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
    ensure              => 'present',
    vhost               => 'release',
    location            => '/static/',
    ssl                 => true,
    ssl_only            => true,
    www_root            => '/usr/share/landing_page',
    location_cfg_append => {
      'error_page 403'         => '/fuel-infra/403.html',
      'error_page 404'         => '/fuel-infra/404.html',
      'error_page 500 502 504' => '/fuel-infra/5xx.html',
    }
  }

  ::nginx::resource::location { 'release-error-pages' :
    ensure   => 'present',
    vhost    => 'release',
    location => '~ ^\/(mirantis|fuel-infra)\/(403|404|5xx)\.html$',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/error_pages',
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
