class nginx {
  include nginx::params

  include nginx::service
  include system::tools
  include zabbix::agent

  $packages = $nginx::params::packages
  $service = $nginx::params::service

  package { $packages :
    ensure => latest,
  }

  file { 'nginx.conf' :
    path => '/etc/nginx/nginx.conf',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('nginx/nginx.conf.erb'),
  }

  file { 'default.conf-enabled' :
    path => '/etc/nginx/sites-enabled/default',
    ensure => absent,
  }

  file { 'default.conf-available' :
    path => '/etc/nginx/sites-available/default',
    ensure => absent,
  }

  file { 'stub_status.conf-available' :
    path => '/etc/nginx/sites-available/stub_status.conf',
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'root',
    content => template('nginx/stub_status.conf.erb'),
  }

  file { 'stub_status.conf-enabled' :
    path => '/etc/nginx/sites-enabled/stub_status.conf',
    ensure => 'link',
    target => '/etc/nginx/sites-available/stub_status.conf',
  }

  file { 'nginx-zabbix-items' :
    path => '/etc/zabbix/zabbix_agentd.conf.d//nginx.conf',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('nginx/zabbix_items.conf.erb'),
  }

  Class['zabbix::agent']->
    Package[$packages]->
    Class['system::tools']->
    File['stub_status.conf-available']->
    File['stub_status.conf-enabled']->
    File['nginx-zabbix-items']~>
    File['nginx.conf']->
    File['default.conf-available']->
    File['default.conf-enabled']~>
    Class['nginx::service']

  File['nginx.conf']->
    File['default.conf-available']->
    File['default.conf-enabled']~>
    Class['nginx::service']

  Class['zabbix::agent']->
    File['stub_status.conf-available']->
    File['stub_status.conf-enabled']~>
    Class['nginx::service']
}
