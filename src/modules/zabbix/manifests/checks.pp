define zabbix::checks () {
  file { $title :
    path => "/etc/zabbix/zabbix_agentd.conf.d/${title}",
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template("zabbix/checks/${title}.erb"),
  }
}
