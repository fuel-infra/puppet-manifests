# Class: nginx
#
class nginx (
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $create_www_dir = false,
) {
  include nginx::params

  include nginx::service
  include system::tools

  $packages = $nginx::params::packages
  $service = $nginx::params::service

  package { $packages :
    ensure => 'present',
  }

  if ($create_www_dir) {
    file { '/var/www' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
    }
  }

  file { '/etc/nginx/sites-available/stub_status.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('nginx/stub_status.conf.erb'),
    require => [
      Class['system::tools'],
      Package[$packages]
    ]
  }->
  file { '/etc/nginx/sites-enabled/stub_status.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/stub_status.conf',
  }->
  file { '/etc/nginx/nginx.conf' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('nginx/nginx.conf.erb'),
  }->
  file { '/etc/nginx/sites-enabled/default' :
    ensure    => 'absent',
  }->
  file { '/etc/nginx/sites-available/default' :
    ensure    => 'absent',
  }~>
  Service['nginx']

  class { 'zabbix::item' :
    name     => 'nginx',
    template => 'nginx/zabbix_items.conf.erb',
  }

  file { '/var/lib/nginx/cache' :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0700',
    require => Package[$packages],
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => 80,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
