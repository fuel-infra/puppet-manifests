Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

package { 'iptables-persistent' :
  ensure => installed,
}->
resources { "firewall" :
  purge => true,
}

class { ['firewall_defaults::pre', 'firewall_defaults::post'] :}
Firewall {
    before  => Class['firewall_defaults::post'],
}


class class_default {
  include dpkg
  include ntp
  include puppet
  include ssh
  include zabbix_agent
}

class jenkins_slave {
  include class_default
  include jenkins_swarm_slave
  include libvirt
  include venv
  include postgresql
  include system_tests
  include transmission_daemon
}

class torrent_tracker {
  include class_default
  include opentracker
}


node default {
  include class_default
}

node /mc([0-2]+)n([1-8]{1})-(msk|srt)\.(msk|srt)\.mirantis\.net/ {
  include jenkins_slave
}

node 'ctorrent-msk.msk.mirantis.net' {
  include torrent_tracker
}

node /(ss0078.svwh.net|fuel-jenkins2.mirantis.com)/ {
  $external_host = true
  include jenkins_slave
}

