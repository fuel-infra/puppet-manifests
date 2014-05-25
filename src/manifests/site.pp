Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  provider => 'shell',
}

#class { ['firewall_defaults::pre', 'firewall_defaults::post'] :}

class common {
  include dpkg
  include firewall_defaults::pre
  include firewall_defaults::post
  include ntp
  include puppet
  include ssh::sshd
  include zabbix::agent
}

class jenkins_slave {
  include common
  include libvirt
  include venv
  include postgresql
  include ssh::authorized_keys
  include system_tests
  include transmission_daemon

  if $external_host == true {
    include jenkins_standalone_slave
  } else {
    include jenkins_swarm_slave
  }
}

class torrent_tracker {
  include common
  include ssh::authorized_keys
  include opentracker
}

class pxe_deployment {
  include common
  include pxetool
  include ssh::authorized_keys
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

node /(seed-(eu|us)([0-9]{2,})\.mirantis\.com)/ {
  $external_host = true

  include common
  include nginx
  include nginx::share
  include seed::web
  include torrent_tracker
}

node /(ss0078\.svwh\.net|fuel-jenkins([0-9]+)\.mirantis\.com)/ {
  $external_host = true

  include jenkins_slave
}

node /srv(07|08|11)-(msk|srt).(msk|srt).mirantis.net/ {
  include srv
}

node /(pxe-product\.msk\.mirantis\.net|jenkins-product\.srt\.mirantis\.net)/ {
  include pxe_deployment
}
