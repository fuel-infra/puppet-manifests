class pxetool {
  include nginx
  include uwsgi

  include pxetool::params

  # configuration
  $additional_repos = $pxetool::params::additional_repos
  $config = $pxetool::params::config
  $mirror = $pxetool::params::mirror
  $nginx_conf = $pxetool::params::nginx_conf
  $nginx_conf_link = $pxetool::params::nginx_conf_link
  $packages = $pxetool::params::packages

  # installing required $packages
  package { $packages :
    ensure => latest,
  }

  # creating database schema
  exec { 'pxetool-syncdb' :
    command => '/usr/share/pxetool/webapp/pxetool/manage.py syncdb --noinput',
    user => 'www-data',
  }

  # running migrations
  exec { 'pxetool-migratedb' :
    command => '/usr/share/pxetool/webapp/pxetool/manage.py migrate --all',
    user => 'www-data',
  }

  # /etc/pxetool.py
  # pxetool main configuration file
  file { $config :
    path => $config,
    ensure => 'present',
    mode => '0600',
    owner => 'www-data',
    content => template('pxetool/pxetool.py.erb'),
  }

  # /etc/nginx/sites-available/pxetool.conf
  # virtual host file for nginx
  file { $nginx_conf :
    path => $nginx_conf,
    ensure => 'present',
    mode => '0644',
    owner => 'root',
    content => template('pxetool/nginx.conf.erb'),
  }

  # /etc/nginx/sites-enabled/pxetool.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure => 'link',
    target => $nginx_conf,
  }

  Package[$packages]->
    Class['nginx']->
    File[$config]->
    Exec['pxetool-syncdb']->
    Exec['pxetool-migratedb']->
    File[$nginx_conf]->
    File[$nginx_conf_link]~>
    Class['uwsgi']~>
    Class['nginx::service']

    Class['nginx']
      File[$config]~>
      Class['uwsgi']~>
      Class['nginx::service']

    Class['nginx']->
      File[$nginx_conf]->
      File[$nginx_conf_link]~>
      Class['nginx::service']
}
