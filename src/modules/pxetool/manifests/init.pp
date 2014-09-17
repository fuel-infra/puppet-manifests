# Class: pxetool
#
class pxetool (
  $additional_repos = $::pxetool::params::mirror,
  $apply_firewall_rules = $::pxetool::params::apply_firewall_rules,
  $config = $::pxetool::params::config,
  $firewall_allow_sources = $::pxetool::params::firewall_allow_sources,
  $mirror = $::pxetool::params::mirror,
  $nginx_conf = $::pxetool::params::nginx_conf,
  $nginx_conf_link = $::pxetool::params::nginx_conf_link,
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

  # /etc/nginx/sites-available/pxetool.conf
  # virtual host file for nginx
  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('pxetool/nginx.conf.erb'),
    require => Class['nginx'],
  }~>
  Service['nginx']

  # /etc/nginx/sites-enabled/pxetool.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure  => 'link',
    target  => $nginx_conf,
    require => File[$nginx_conf],
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
