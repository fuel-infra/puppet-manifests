class zabbix_agent {
  include zabbix_agent::params

  $packages = $zabbix_agent::params::packages
  $service = $zabbix_agent::params::service

  file { 'zabbix_agentd.conf':
    path => '/etc/zabbix/zabbix_agentd.conf',
    owner => 'root',
    group => 'root',
    content => template('zabbix_agent/zabbix_agentd.conf.erb'),
  }

  package { $packages:
    ensure => latest,
  }

  service { $service:
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Class['dpkg'] ->
    Package[$packages] ->
    File['zabbix_agentd.conf'] ~>
    Service[$service]

  File['zabbix_agentd.conf'] ~>
    Service[$service]
}
