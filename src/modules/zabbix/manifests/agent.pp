class zabbix::agent {
  include zabbix::params

  $checks = $zabbix::params::checks
  $config = $zabbix::params::agent_config
  $packages = $zabbix::params::agent_packages
  $service = $zabbix::params::agent_service
  $server = $zabbix::params::server
  $sudoers = $zabbix::params::agent_sudoers

  file { $config :
    path => $config,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/zabbix_agentd.conf.erb'),
  }

  file { $sudoers :
    path => $sudoers,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/sudoers.erb')
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
    $firewall = hiera_hash('firewall')

    $port = 10050
    $proto = 'tcp'
    $allowed_ips = $firewall['known_networks']

    each($allowed_ips) |$ip| {
      firewall { "1000 allow zabbix connections - src ${ip} ; dst ${proto}/${port}" :
        dport => $port,
        proto => $proto,
        source => $ip,
        action => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }


  Class['dpkg']->
    Package[$packages]->
    File[$config]->
    File[$sudoers]->
    Zabbix::Checks[$checks]~>
    Service[$service]

  File[$sudoers]->
    Zabbix::Checks[$checks]~>
    Service[$service]

  File[$config]->
    Zabbix::Checks[$checks]~>
    Service[$service]

  Zabbix::Checks[$checks]~>
    Service[$service]
}
