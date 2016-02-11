# Class: pxetool
#
# This class deploys fully functional Django powered PXEtool tool which allows
# to configure DHCP servers to boot, install OS on machines and configure it.
#
# Parameters:
#   [*ssh_id_rsa,*] - ssh private key contents
#   [*ssh_id_rsa_pub,*] - ssh public key contents
#   [*config*] - PXEtool configuration file path
#   [*database_engine*] - Django database engine to use
#   [*database_host*] - database host
#   [*database_name*] - database name
#   [*database_password*] - database password
#   [*database_port*] - database port
#   [*database_user*] - database user name
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log file format
#   [*packages*] - additional packages (example: database library for Python)
#   [*server_name*] - service hostname
#   [*ssl_cert_file*] - ssl certificate file path
#   [*ssl_cert_file_content*] - ssl certificate file contents
#   [*ssl_key_file*] - ssl private key file path
#   [*ssl_key_file_content*] - ssl private key file contents
#   [*user*] - user to install application on
#
class pxetool::master(
  $ssh_id_rsa,
  $ssh_id_rsa_pub,
  $config                = '/etc/pxetool.yaml',
  $database_engine       = 'django.db.backends.sqlite3',
  $database_host         = undef,
  $database_name         = '/var/lib/pxetool/database.sqlite3',
  $database_password     = undef,
  $database_port         = undef,
  $database_user         = undef,
  $nginx_access_log      = '/var/log/nginx/access.log',
  $nginx_error_log       = '/var/log/nginx/error.log',
  $nginx_log_format      = undef,
  $packages              = [],
  $server_name           = $::fqdn,
  $ssl_cert_file         = '/etc/ssl/certs/pxetool.crt',
  $ssl_cert_file_content = '',
  $ssl_key_file          = '/etc/ssl/private/pxetool.key',
  $ssl_key_file_content  = '',
  $user                  = 'pxetool',
) {
  if(!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }
  if(!defined(Class['::uwsgi'])) {
    class { '::uwsgi' :}
  }

  # installing required $packages
  $base_packages = [
    'python-django-pxetool',
    'redis-server',
  ]
  ensure_packages($base_packages)
  ensure_packages($packages)

  user { $user :
    ensure     => 'present',
    managehome => false,
    home       => "/var/lib/${user}",
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  file { [ "/var/lib/${user}", "/var/lib/${user}/.ssh" ] :
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0755',
    require => User[$user],
  }

  file { "/var/lib/${user}/.ssh/id_rsa" :
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0400',
    content => $ssh_id_rsa,
    require => File["/var/lib/${user}/.ssh"],
  }

  file { "/var/lib/${user}/.ssh/id_rsa.pub" :
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0400',
    content => $ssh_id_rsa_pub,
    require => File["/var/lib/${user}/.ssh"],
  }

  # /etc/pxetool.yaml
  # pxetool main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0400',
    owner   => $user,
    group   => $user,
    content => template('pxetool/pxetool.yaml.erb'),
  }

  exec { 'pxetool-syncdb' :
    command     => 'django-admin syncdb --noinput',
    environment => [
      'DJANGO_SETTINGS_MODULE=pxetool.settings',
      "PXETOOL_CFG=${config}",
    ],
    user        => $user,
    require     => [
      Package[$base_packages],
      Package[$packages],
      User[$user],
      File['/etc/pxetool.yaml'],
    ]
  }

  exec { 'pxetool-migratedb' :
    command     => 'django-admin migrate --all',
    environment => [
      'DJANGO_SETTINGS_MODULE=pxetool.settings',
      "PXETOOL_CFG=${config}",
    ],
    user        => $user,
    require     => Exec['pxetool-syncdb'],
    notify      => Service['uwsgi'],
  }

  ::nginx::resource::vhost { 'pxetool' :
    ensure              => 'present',
    listen_port         => 80,
    server_name         => [$server_name],
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    uwsgi               => '127.0.0.1:7931',
    location_cfg_append => {
      uwsgi_connect_timeout => '3m',
      uwsgi_read_timeout    => '3m',
      uwsgi_send_timeout    => '3m',
    }
  }

  ::nginx::resource::location { 'pxetool-static' :
    ensure   => 'present',
    vhost    => 'pxetool',
    location => '/static/',
    www_root => '/usr/lib/python2.7/dist-packages/pxetool_ui',
  }

  ::nginx::resource::location { 'pxetool-docs' :
    ensure   => 'present',
    vhost    => 'pxetool',
    location => '/docs/',
    www_root => '/usr/share/pxetool',
  }

  if (
    $ssl_cert_file and $ssl_cert_file_content != '' and
    $ssl_key_file and $ssl_key_file_content != ''
  ) {
    file { $ssl_cert_file :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_content,
    }
    file { $ssl_key_file :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_content,
    }
    Nginx::Resource::Vhost <| title == 'pxetool' |>  {
      ssl         => true,
      ssl_cert    => $ssl_cert_file,
      ssl_key     => $ssl_key_file,
      ssl_port    => 443,
      listen_port => 443,
      require     => [
        File[$ssl_cert_file],
        File[$ssl_key_file],
      ],
    }
    Nginx::Resource::Location <| title == 'pxetool-static' |> {
      ssl         => true,
      ssl_only    => true,
    }
    Nginx::Resource::Location <| title == 'pxetool-docs' |> {
      ssl         => true,
      ssl_only    => true,
    }
    ::nginx::resource::vhost { 'pxetool-redirect' :
      ensure              => 'present',
      listen_port         => $http_port,
      www_root            => '/var/www',
      server_name         => [$server_name],
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${server_name}\$request_uri",
      }
    }
  }

  uwsgi::application { 'pxetool' :
    plugins => 'python',
    module  => 'pxetool.wsgi',
    env     => "PXETOOL_CFG=${config}",
    uid     => $user,
    gid     => $user,
    socket  => '127.0.0.1:7931',
  }

  class { 'supervisord':
    service_name     => 'supervisor',
    init_script      => '/etc/init.d/supervisor',
    package_provider => 'apt',
    executable       => '/usr/bin/supervisord',
    executable_ctl   => '/usr/bin/supervisorctl',
  }
}
