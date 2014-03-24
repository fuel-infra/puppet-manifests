class zabbix_agent {
  include zabbix_agent::params
  #include zabbix_agent::checks

  $checks = $zabbix_agent::params::checks
  $packages = $zabbix_agent::params::packages
  $service = $zabbix_agent::params::service
  $zabbix_nets = $zabbix_agent::params::zabbix_nets

  file { 'zabbix_agentd.conf' :
    path => '/etc/zabbix/zabbix_agentd.conf',
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix_agent/zabbix_agentd.conf.erb'),
  }

  zabbix_agent::checks { $checks :}

  package { $packages :
    ensure => latest,
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Class['firewall_defaults::pre'] ->
  firewall { '200 allow zabbix connections' :
    dport => 10050,
    source => $zabbix_nets,
    action => 'accept',
  }

  Class['dpkg'] ->
    Package[$packages] ->
    File['zabbix_agentd.conf'] ->
    Zabbix_agent::Checks[$checks] ~>
    Service[$service]

  File['zabbix_agentd.conf'] ->
    Zabbix_agent::Checks[$checks] ~>
    Service[$service]

  Zabbix_agent::Checks[$checks] ~>
    Service[$service]
}
