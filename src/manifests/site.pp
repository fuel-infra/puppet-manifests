# Defaults

Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  provider => 'shell',
}

File {
  replace => true,
}

# Class definitions

class common {
  include dpkg
  include firewall_defaults::pre
  include firewall_defaults::post
  include ntp
  include puppet
  include ssh::authorized_keys
  include ssh::sshd
  include system
  include zabbix::agent
}

class jenkins_slave {
  include common
  include libvirt
  include venv
  include postgresql
  include system_tests
  include transmission_daemon

  if $external_host == true {
    include jenkins::slave
  } else {
    include jenkins::swarm_slave
  }
}

class torrent_tracker {
  include common
  include opentracker
}

class pxe_deployment {
  include common
  include pxetool
}

class srv {
  include common
  include nginx
  class { 'nginx::share': fuelweb_iso_create => true }
  include ssh::sshd
  include ssh::ldap
}

# Nodes definitions

node /(mc([0-2]+)n([1-8]{1})-(msk|srt)|srv(14|15|16|17|18|19|20|21)-msk)\.(msk|srt)\.mirantis\.net/ {
  include build_fuel_iso
  class { 'nginx::share': fuelweb_iso_create => true }
  include jenkins_slave
  include ssh::ldap
}

node 'ctorrent-msk.msk.mirantis.net' {
  include torrent_tracker
}

node /(seed-(cz|us)1\.fuel-infra\.org)/ {
  $external_host = true

  include common
  include nginx
  class { 'nginx::share': fuelweb_iso_create => true }
  include seed::web
  include torrent_tracker
}

node /(ss0078\.svwh\.net|fuel-jenkins([0-9]+)\.mirantis\.com|(pkgs)?ci-slave([0-9]{2})\.fuel-infra\.org)/ {
  $external_host = true
  include jenkins_slave
}

node /(srv(07|08|11)|jenkins-product)-(msk|srt|kha)\.(msk|srt|vm)\.mirantis\.net/ {
  include srv
  include jenkins_slave
  include build_fuel_iso
}

node /pxe-product-(msk|srt)\.(msk|srt)\.mirantis\.net/ {
  include pxe_deployment
}

node /mirror(\d+)\.fuel-infra\.org/ {
  $external_host = true

  include common
  include nginx
  include nginx::share
}

node /build(\d+)\.fuel-infra\.org/ {
  $external_host = true

  include common
  include build_fuel_iso
  include jenkins::slave
}

node 'monitor-product.vm.mirantis.net' {
  include common
  include zabbix::server
}

node 'test-server' {
  # puppet apply --certname test-server -v -d /etc/puppet/manifests/site.pp

  include virtual::repos

  realize Repository['jenkins']
  realize Repository['docker']
}
