# Class: seed::web
#
class seed::web {
  include seed::params

  include nginx
  include nginx::share
  include uwsgi

  $allowed_ips = $seed::params::allowed_ips

  file { '/etc/nginx/sites-available/seed.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('seed/nginx.conf.erb'),
  }

  file { '/etc/nginx/sites-enabled/seed.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/seed.conf',
  }

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

  Class['dpkg']->
    Class['nginx']->
    File['nginx-seed.conf-available']->
    File['nginx-seed.conf-enabled']->
    Class['nginx::share']->
    Class['nginx::service']
}
