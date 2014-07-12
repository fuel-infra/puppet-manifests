class seed::web {
  include seed::params

  include nginx
  include nginx::share
  include uwsgi

  $allowed_ips = $seed::params::allowed_ips

  file { 'nginx-seed.conf-available' :
    path => '/etc/nginx/sites-available/seed.conf',
    content => template('seed/nginx.conf.erb'),
    mode => '0644',
    owner => 'root',
    group => 'root',
  }

  file { 'nginx-seed.conf-enabled' :
    path => '/etc/nginx/sites-enabled/seed.conf',
    ensure => 'link',
    target => '/etc/nginx/sites-available/seed.conf',
  }

  if $external_host {
    Class['firewall_defaults::pre'] ->
    firewall { '1000 allow seed connections' :
      dport => 17333,
      source => $allowed_ips,
      action => 'accept',
    }
  }

  Class['dpkg']->
    Class['nginx']->
    File['nginx-seed.conf-available']->
    File['nginx-seed.conf-enabled']->
    Class['nginx::share']->
    Class['nginx::service']
}
