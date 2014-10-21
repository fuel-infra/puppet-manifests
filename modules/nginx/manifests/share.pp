# Class: nginx::share
#
class nginx::share(
  $fuelweb_iso_create = false,
  $fwm_create = false
) {
  include nginx::params

  include nginx
  include nginx::service

  $autoindex = $nginx::params::autoindex
  $server_name = $nginx::params::server_name
  $service = $nginx::params::service

  file { '/etc/nginx/sites-available/share.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('nginx/share.conf.erb'),
    require => Class['nginx']
  }->
  file { '/etc/nginx/sites-enabled/share.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/share.conf',
  }->
  file { '/var/www' :
    ensure => 'directory',
  }~>
  Service['nginx']

  if($fuelweb_iso_create) {
    file { '/var/www/fuelweb-iso' :
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0775',
    }
  }

  if($fwm_create) {
    file { '/var/www/fwm' :
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0775',
    }
  }

  if $external_host {
    Class['firewall_defaults::pre'] ->
    firewall { '1000 allow nginx connections' :
      dport  => 80,
      action => 'accept',
    }
  }
}
