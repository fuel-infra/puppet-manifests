service { "zabbix-agent":
    ensure  => "running",
    enable  => "true",
    require => Package["zabbix-agent"],
}

file { "zabbix_agentd.conf":
    name => "/etc/zabbix/zabbix_agentd.conf",
    notify => Service['zabbix-agent'],
    ensure => present,
        owner => root,
        group => $admingroup,
        mode  => 644,
    content => template("zabbix-agent/zabbix_agentd.conf.erb"),
    require => Package['zabbix-agent']
}

