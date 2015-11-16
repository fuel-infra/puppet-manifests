# Defaults

Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  provider => 'shell',
}

File {
  replace => true,
}

if($::osfamily == 'Debian') {
  Exec['apt_update'] -> Package <| |>
}

stage { 'pre' :
  before => Stage['main'],
}

$gitrevision = '$Id$'

notify { "Revision : ${gitrevision}" :}

file { '/var/lib/puppet' :
  ensure => 'directory',
  owner  => 'puppet',
  group  => 'puppet',
  mode   => '0755',
}

file { '/var/lib/puppet/gitrevision.txt' :
  ensure  => 'present',
  owner   => 'root',
  group   => 'root',
  mode    => '0444',
  content => $gitrevision,
  require => File['/var/lib/puppet'],
}

# Nodes definitions

# Jenkins Product slave to build documentation
node /docs-slave01.vm.mirantis.net/ {
  class { '::fuel_project::jenkins::slave' :}
}

node /(infra|fuel)-jenkins(\d+)\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::master' :}
}

node /packtest([0-9]{2})\.(bud|infra)\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests => true,
    ldap      => true,
  }
}

node /perestroika-slave([0-9]{2})\.infra\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests => true,
    ldap      => true,
  }
}

node /mirror(\d+)\.fuel-infra\.org/ {
  $external_host = true

  class { '::fuel_project::common' :
    external_host => $external_host
  }
  include nginx
  include nginx::share
}

node /build(\d+)\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::slave' :
    external_host  => true,
    build_fuel_iso => true,
  }
}

node /irc-bouncer([0-9]{2})\.fuel-infra\.org/ {
  class { '::fuel_project::znc' :
    apply_firewall_rules => true,
  }
}

node /zabbix-tst01\.vm\.mirantis\.net/ {
  class { '::fuel_project::zabbix::server' :}
}

node /fuel-puppet(-tst)?\.vm\.mirantis\.net/ {
  class { '::fuel_project::puppet::master' :
    apply_firewall_rules => true,
    external_host        => true,
  }
}

node 'lab-cz.vm.mirantis.net' {
  class { '::fuel_project::lab_cz' :
    external_host => false,
  }
}

node 'review-solr-tst01.vm.mirantis.net' {
  class { '::fuel_project::common' :}
}

node 'devops-tools.vm.mirantis.net' {
  class { '::fuel_project::devops_tools' :}
}

node /tools([0-9]{2})-(msk|bud|srt|kha|poz)\.infra\.mirantis\.net/ {
  class { '::fuel_project::devops_tools' :}
}

node /gerrit([0-9]{2})-(msk|bud|srt|kha|poz).fuel-infra.org/ {
  class { '::fuel_project::gerrit' :}
}

node 'osci-jenkins2.vm.mirantis.net' {
  class { '::fuel_project::jenkins::master' :}
}

node /tpi\d\d\.bud\.mirantis\.net/ {
  class { '::fuel_project::tpi::lab' :}
}

node /tpi-s\d.bud.mirantis.net/ {
  class { '::fuel_project::tpi::server' :}
}

node 'tpi-puppet.vm.mirantis.net' {
  class { '::fuel_project::tpi::puppetmaster' :}
}

node 'demo.fuel-infra.org' {
  class { '::fuel_project::nailgun_demo' :
    apply_firewall_rules => true,
  }
}

node 'gfs01-msk.vm.mirantis.net' {
  class { '::fuel_project::glusterfs' :  }
}

node 'gfs02-msk.vm.mirantis.net' {
  class { '::fuel_project::glusterfs' :
    create_pool     => true,
    gfs_pool        => [ 'gfs01-msk.vm.mirantis.net','gfs02-msk.vm.mirantis.net' ],
    gfs_volume_name => 'data',
  }
}

node 'plugins-msk.vm.mirantis.net' {
  class { '::fuel_project::jenkins::slave' :
    install_docker => true,
  }
}

node 'mongo-secondary-1.vm.mirantis.net' {
  class {'::fuel_project::mongo_common':
    primary => false,
  }
}

node 'mongo-secondary-2.vm.mirantis.net' {
  class {'::fuel_project::mongo_common':
    primary => false,
  }
}

node /storage([0-9]{2})-(msk|srt)\.devops\.mirantis\.net/ {
  class { '::fuel_project::roles::storage' :}
}

node 'mongo-primary.vm.mirantis.net' {
  class {'::fuel_project::mongo_common':
    primary => true,
  }
}

node 'obs-1.mirantis.com' {
  class { '::obs_server' :}
}

node /racktables.(vm\.mirantis\.net|test\.local)/ {
  class { '::fuel_project::racktables' : }
}

# Sandbox

node 'jenkins-sandbox.infra.mirantis.net' {
  class { '::fuel_project::jenkins::master' : }
}

node /slave([0-1])([1-2])-sandbox\.infra.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave': }
}

# Jenkins master testing

node 'devops-jenkins-test.vm.mirantis.net' {
  class { '::fuel_project::jenkins::master' :}
}

node 'slave01-tst.vm.mirantis.net' {
  class { '::fuel_project::jenkins::slave' :}
}

# Default
node default {
  $classes = hiera('classes', '')
  if ($classes) {
    validate_array($classes)
    hiera_include('classes')
  } else {
    notify { 'Default node invocation' :}
  }
}
