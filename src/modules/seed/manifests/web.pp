class seed::web {
  include seed::params
  include nginx
  include nginx::share
  include uwsgi

  $seed_conf = $seed::params::seed_conf
  $nginx_conf = $seed::params::nginx_conf
  $uwsgi_conf = $seed::params::uwsgi_conf
  $packages = $seed::params::packages
  $allowed_ips = $seed::params::allowed_ips

  package { $packages :
    ensure => 'latest',
  }

  file { $seed_conf :
    path => $seed_conf,
    content => template('seed/seed.py.erb'),
    mode => '0644',
    owner => 'root',
    group => 'root',
  }

  file { $nginx_conf :
    path => $nginx_conf,
    content => template('seed/nginx.conf.erb'),
    mode => '0644',
    owner => 'root',
    group => 'root',
  }

  exec { "${nginx_conf}-symlink" :
    command => 'rm -f /etc/nginx/sites-enabled/seed.conf ; ln -s /etc/nginx/sites-available/seed.conf /etc/nginx/sites-enabled/seed.conf',
    refreshonly => true,
  }

  file { $uwsgi_conf :
    path => $uwsgi_conf,
    content => template('seed/uwsgi.yaml.erb'),
    mode => '0644',
    owner => 'root',
    group => 'root',
  }

  exec { "${uwsgi_conf}-symlink" :
    command => 'rm -f /etc/uwsgi/apps-enabled/seed.yaml ; ln -s /etc/uwsgi/apps-available/seed.yaml /etc/uwsgi/apps-enabled/seed.yaml',
    refreshonly => true,
  }

  file { '/var/www/fuelweb-iso' :
    ensure => 'directory',
  }

  if $external_host {
    Class['firewall_defaults::pre'] ->
    firewall { '1000 allow seed connections' :
      dport => 17333,
      source => $allowed_ips,
      action => 'accept',
    }
  }

  Class['nginx::share']->
    File['/var/www/fuelweb-iso']->
    File[$seed_conf]->
    File[$nginx_conf]~>
    Exec["${nginx_conf}-symlink"]
    File[$uwsgi_conf]~>
    Exec["${uwsgi_conf}-symlink"]
    Service['nginx']~>
    Service['uwsgi']
}
