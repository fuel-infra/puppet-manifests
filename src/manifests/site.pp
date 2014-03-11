Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

class libvirtnode {
  include dpkg
  include libvirt
  include venv
  include postgresql
  include system_tests
  include zabbix_agent
}

class zabbixnode {
  include dpkg
  include zabbix
}

node 'mc2n7-srt.srt.mirantis.net' {
  include libvirtnode
}

