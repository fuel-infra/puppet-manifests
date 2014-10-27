# Class: pxetool
#
class pxetool (
  $additional_repos = $::pxetool::params::additional_repos,
  $apply_firewall_rules = $::pxetool::params::apply_firewall_rules,
  $config = $::pxetool::params::config,
  $disk_pattern = $::pxetool::params::disk_pattern,
  $firewall_allow_sources = $::pxetool::params::firewall_allow_sources,
  $mirror = $::pxetool::params::mirror,
  $package = $::pxetool::params::package,
  $puppet_master = $::pxetool::params::puppet_master,
  $root_password_hash = $::pxetool::params::root_password_hash,
  $service_port = $::pxetool::params::service_port,
  $timezone = $::pxetool::params::timezone,
) inherits ::pxetool::params {
  include nginx
  include uwsgi

  include pxetool::params

  # installing required $packages
  ensure_packages($package)

  # creating database schema
  exec { 'pxetool-syncdb' :
    command => '/usr/share/pxetool/webapp/pxetool/manage.py syncdb --noinput',
    user    => 'www-data',
    require => Package[$package],
  }

  # running migrations
  exec { 'pxetool-migratedb' :
    command => '/usr/share/pxetool/webapp/pxetool/manage.py migrate --all',
    user    => 'www-data',
    require => Exec['pxetool-syncdb']
  }

  # /etc/pxetool.py
  # pxetool main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0600',
    owner   => 'www-data',
    group   => 'www-data',
    content => template('pxetool/pxetool.py.erb'),
    require => [
      Exec['pxetool-syncdb'],
      Exec['pxetool-migratedb']
    ]
  }~>
  Service['uwsgi']

  if (!defined(Class['nginx'])) {
    class { '::nginx' :}
  }
  nginx::resource::vhost { 'pxetool' :
    ensure              => 'present',
    listen_port         => 80,
    server_name         => [$::fqdn],
    uwsgi               => '127.0.0.1:7931',
    location_cfg_append => {
      uwsgi_connect_timeout => '3m',
      uwsgi_read_timeout    => '3m',
      uwsgi_send_timeout    => '3m',
    }
  }

  nginx::resource::location { 'pxetool-static' :
    ensure   => 'present',
    vhost    => 'pxetool',
    location => '/static/',
    www_root => '/usr/share/pxetool/webapp/pxetool',
  }

  uwsgi::application { 'pxetool' :
    plugins => 'python',
    uid     => 'www-data',
    gid     => 'www-data',
    socket  => '127.0.0.1:7931',
    chdir   => '/usr/share/pxetool/webapp/pxetool',
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
