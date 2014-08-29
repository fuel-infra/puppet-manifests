# Class: seed::web
#
class seed::web {
  include seed::params

  include nginx
  include nginx::service
  include nginx::share
  include uwsgi

  $allowed_ips = $seed::params::allowed_ips

  file { '/etc/nginx/sites-available/seed.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('seed/nginx.conf.erb'),
    require => Class['nginx'],
  }->
  file { '/etc/nginx/sites-enabled/seed.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/seed.conf',
  }~>
  Service['nginx']

  if $external_host {
    each($allowed_ips) |$ip| {
      firewall { "1000 allow seed connections - ${ip}:17333" :
        dport   => 17333,
        source  => $ip,
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
