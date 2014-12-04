# Class: release_status
#
class release_status (
  $apply_firewall_rules = $::release_status::params::apply_firewall_rules,
  $config = $::release_status::params::config,
  $firewall_allow_sources = $::release_status::params::firewall_allow_sources,
  $package = $::release_status::params::package,
  $timezone = $::release_status::params::timezone,
  $mysql_database = $::release_status::params::mysql_database,
  $mysql_user = $::release_status::params::mysql_user,
  $mysql_password = $::release_status::params::mysql_password,
  $mysql_host = $::release_status::params::mysql_host,
  $mysql_port = $::release_status::params::mysql_port,
  $nginx_server_name = $::release_status::params::nginx_server_name,
  $app_user = $::release_status::params::app_user,
  $ssl_cert_file = $::release_status::params::ssl_cert_file,
  $ssl_key_file = $::release_status::params::ssl_key_file,
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
) inherits ::release_status::params {

  # installing required $packages
  ensure_packages($package)

  # creating application user and group
  user { $app_user :
    ensure => 'present',
  }

  # install mysql packages and apply mysql settings
  class { 'mysql::server' :}
  class { 'mysql::client' :}
  class { 'mysql::server::account_security' :}
  mysql::db { $mysql_database:
    user     => $mysql_user,
    password => $mysql_password,
    host     => $mysql_host,
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }

  # /usr/share/release-status/release/settings.py
  # release_status main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0600',
    owner   => $app_user,
    group   => $app_user,
    content => template('release_status/release_status.py.erb'),
    require => [
      User[$app_user],
      Package[$package],
      Mysql::Db[$mysql_database],
    ]
  }

  # creating database schema
  exec { 'release_status-syncdb' :
    command => '/usr/share/release-status/manage.py syncdb --noinput',
    user    => $app_user,
    require => File[$config],
  }

  # running migrations
  exec { 'release_status-migratedb' :
    command => '/usr/share/release-status/manage.py migrate --all',
    user    => $app_user,
    require => Exec['release_status-syncdb']
  }~>
  Service['uwsgi']

  if (!defined(Class['nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'release-http' :
    ensure              => 'present',
    server_name         => [$nginx_server_name],
    listen_port         => 80,
    www_root            => '/var/www',
    location_cfg_append => {
      return => '301 https://$server_name$request_uri',
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
    uwsgi               => '127.0.0.1:7931',
    location_cfg_append => {
      uwsgi_connect_timeout => '3m',
      uwsgi_read_timeout    => '3m',
      uwsgi_send_timeout    => '3m',
    }
  }

  ::nginx::resource::location { 'release-static' :
    ensure   => 'present',
    vhost    => 'release',
    location => '/static/',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/release-status',
  }

  ::uwsgi::application { 'release_status' :
    plugins => 'python',
    uid     => $app_user,
    gid     => $app_user,
    socket  => '127.0.0.1:7939',
    chdir   => '/usr/share/release-status',
    module  => 'release.wsgi',
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
      before  => Nginx::Resource::Vhost['release'],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
      before  => Nginx::Resource::Vhost['release'],
    }
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
