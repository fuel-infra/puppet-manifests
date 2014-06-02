class zabbix::agent {
  include zabbix::params

  $checks = $zabbix::params::checks
  $config = $zabbix::params::agent_config
  $packages = $zabbix::params::agent_packages
  $service = $zabbix::params::agent_service
  $server_fqdn = $zabbix::params::server_fqdn

  file { $config :
    path => $config,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/zabbix_agentd.conf.erb'),
  }

  zabbix::checks { $checks :}

  package { $packages :
    ensure => latest,
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  if $external_host {
    Class['firewall_defaults::pre'] ->
    firewall { '1000 allow zabbix connections' :
      dport => 10050,
      source => $server_fqdn,
      action => 'accept',
    }
  }

  Class['dpkg']->
    Package[$packages]->
    File[$config]->
    Zabbix::Checks[$checks]~>
    Service[$service]

  File[$config]->
    Zabbix::Checks[$checks]~>
    Service[$service]

  Zabbix::Checks[$checks]~>
    Service[$service]
}
