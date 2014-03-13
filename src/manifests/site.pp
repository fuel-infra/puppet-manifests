Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
}

class jenkins_slave {
  include dpkg
  include libvirt
  include venv
  include postgresql
  include system_tests
  include zabbix_agent
  include ssh
  include transmission_daemon

  stage { 'last' :}
  class { 'jenkins_swarm_slave' :
    stage => 'last',
  }
  Stage['main'] -> Stage['last']
}

node /mc2n([1-8]{1})-srt\.srt\.mirantis\.net/ {
  include jenkins_slave
}

