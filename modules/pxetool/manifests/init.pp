# Class: pxetool
#
class pxetool (
  $additional_repos       = [],
  $apply_firewall_rules   = false,
  $config                 = '/etc/pxetool/settings.py',
  $database_engine        = 'django.db.backends.sqlite3',
  $database_host          = '',
  $database_name          = '/usr/share/pxetool/pxetool/database.sqlite3',
  $database_password      = '',
  $database_port          = '',
  $database_user          = '',
  $disk_pattern           = '(\/dev\/sd([a-z]+)|\/dev\/(x)?vd([a-z]+))',
  $firewall_allow_sources = {},
  $mirror                 = 'mirror.yandex.ru',
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = undef,
  $package                = [
    'python-django-pxetool',
    'python-django-pxetool-template-debian-7-amd64',
    'python-django-pxetool-template-ubuntu-14.04-amd64'
  ],
  $puppet_master          = $::fqdn,
  $pxelinux_root          = '/var/lib/tftpboot',
  $pxetool_url            = "http://${::fqdn}",
  $root_password_hash     = '',
  $timezone               = 'UTC',
) {
  if(!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }
  if(!defined(Class['::uwsgi'])) {
    class { '::uwsgi' :}
  }

  # installing required $packages
  ensure_packages($package)

  # /etc/pxetool.py
  # pxetool main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0600',
    owner   => 'www-data',
    group   => 'www-data',
    content => template('pxetool/pxetool.py.erb'),
  }

  file { '/usr/share/pxetool/pxetool/settings.py' :
    ensure  => 'link',
    target  => '/etc/pxetool/settings.py',
    require => File[$config],
  }

  file { '/usr/share/pxetool/pxetool' :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Package[$package],
  }

  exec { 'pxetool-syncdb' :
    command => '/usr/share/pxetool/manage.py syncdb --noinput',
    user    => 'www-data',
    require => [
      Package[$package],
      File['/usr/share/pxetool/pxetool/settings.py'],
      File['/usr/share/pxetool/pxetool'],
    ]
  }

  exec { 'pxetool-migratedb' :
    command => '/usr/share/pxetool/manage.py migrate --all',
    user    => 'www-data',
    require => Exec['pxetool-syncdb'],
    notify  => Service['uwsgi'],
  }

  if (!defined(Class['nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'pxetool' :
    ensure              => 'present',
    listen_port         => 80,
    server_name         => [$::fqdn],
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
    www_root => '/usr/share/pxetool',
  }

  ::uwsgi::application { 'pxetool' :
    plugins => 'python',
    uid     => 'www-data',
    gid     => 'www-data',
    socket  => '127.0.0.1:7931',
    chdir   => '/usr/share/pxetool',
    module  => 'pxetool.wsgi',
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => $service_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
