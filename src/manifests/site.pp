Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

#class { ['firewall_defaults::pre', 'firewall_defaults::post'] :}

class common {
  include dpkg
  include firewall_defaults::pre
  include firewall_defaults::post
  include ntp
  include puppet
  include ssh::sshd
  include zabbix_agent
}

class jenkins_slave {
  include common
  include jenkins_swarm_slave
  include libvirt
  include venv
  include postgresql
  include ssh::authorized_keys
  include system_tests
  include transmission_daemon
}

class torrent_tracker {
  include common
  include ssh::authorized_keys
  include opentracker
}

class srv {
  include common
  include nginx
  include nginx::share
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

node /srv0(7|8|11)-(msk|srt).(msk|srt).mirantis.net/ {
  include srv
}

