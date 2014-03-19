Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

class jenkins_slave {
  include dpkg
  include jenkins_swarm_slave
  include libvirt
  include venv
  include postgresql
  include ssh
  include system_tests
  include transmission_daemon
  include zabbix_agent
}

class torrent_tracker {
  include dpkg
  include opentracker
  include ssh
  include zabbix_agent
}

node default {
  include dpkg
  include ssh
  include zabbix_agent
}

node /mc2n([1-8]{1})-srt\.srt\.mirantis\.net/ {
  include jenkins_slave
}

node 'ctorrent-msk.msk.mirantis.net' {
  include torrent_tracker
}

