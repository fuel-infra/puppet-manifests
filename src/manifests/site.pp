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

class jenkins_slave {
  include dpkg
  include jenkins_swarm_slave
  include libvirt
  include venv
  include postgresql
  include puppet
  include ssh
  include system_tests
  include transmission_daemon
  include zabbix_agent
}

class torrent_tracker {
  include dpkg
  include opentracker
  include puppet
  include ssh
  include zabbix_agent
}

node default {
  include dpkg
  include puppet
  include ssh
  include zabbix_agent
}

node /mc2n([1-8]{1})-srt\.srt\.mirantis\.net/ {
  include jenkins_slave
}

node 'ctorrent-msk.msk.mirantis.net' {
  include torrent_tracker
}

node /(ss0078.svwh.net|fuel-jenkins2.mirantis.com)/ {
  $external_host = true
  include jenkins_slave
}

