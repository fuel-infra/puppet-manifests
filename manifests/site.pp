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

file { '/var/lib/puppet/gitrevision.txt' :
  ensure  => 'present',
  owner   => 'root',
  group   => 'root',
  mode    => '0400',
  content => $gitrevision,
}

# Class: pxe_deployment
#
class pxe_deployment {
  class { '::fuel_project::common' :}
  include pxetool
}

# Nodes definitions

node /(mc([0-9]+)n([0-9]+)|srv([0-9]+))-(msk|srt)\.(msk|srt)\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    fuelweb_iso         => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

# Jenkins Product slave to build documentation
node /docs-slave01.vm.mirantis.net/ {
  class { '::fuel_project::jenkins::slave' :}
}

node /srv(22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|39|40|41|42)-bud\.bud\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    fuelweb_iso         => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node /devops-(01|02)\.mnv\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    fuelweb_iso         => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node /cacher01-(cz|kha|mnv|poz)\.vm\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :}
}

node 'ctorrent-msk.msk.mirantis.net' {
  class { '::fuel_project::common' :
    external_host => false,
  }
  class { '::opentracker' :}
}

node /(seed-(cz|us)1\.fuel-infra\.org)/ {
  class { '::fuel_project::common' :
    external_host => true,
  }
  class { '::fuel_project::seed' :
    external_host                => true,
    apply_firewall_rules         => true,
    tracker_apply_firewall_rules => true,
  }
  class { '::fuel_project::mirror' :
    apply_firewall_rules => true,
  }

  class { '::fuel_project::plugins' :
    apply_firewall_rules => true,
  }

  class { '::fuel_project::updates' :
    apply_firewall_rules => true,
  }
}

node /osci-mirror-(msk|srt|kha)\.(msk|srt|kha)\.mirantis\.net/ {
  class { '::fuel_project::common' :}
  class { '::fuel_project::mirror' :}
}

node /(pkgs)?ci-slave([0-9]{2})\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::slave' :
    external_host       => true,
    run_tests           => true,
    simple_syntax_check => true,
    verify_fuel_web     => true,
    verify_fuel_astute  => true,
    verify_fuel_docs    => true,
    build_fuel_plugins  => true,
    verify_fuel_stats   => true,
    check_tasks_graph   => true,
    fuel_web_selenium   => true,
  }
}

node /packtest([0-9]{2})\.bud\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests => true,
    ldap      => true,
  }
}

node /pxe-product2?-(msk|srt|cz)\.((msk|srt|vm)\.mirantis\.net|fuel-infra\.org)/ {
  include pxe_deployment
}

node /mirror(\d+)\.fuel-infra\.org/ {
  $external_host = true

  class { '::fuel_project::common' :
    external_host => $external_host
  }
  include nginx
  include nginx::share
}

node /mirror-pkgs\.vm\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' : }
  class { '::fuel_project::mirror' : }
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

node /zbxproxy0([0-9]+)-([a-z]+)\.vm\.mirantis\.net/ {
  class { '::fuel_project::zabbix::proxy' :}
}

# FIXME: Could be removed after zbxserver launch
node 'monitor-product.vm.mirantis.net' {
  class { '::fuel_project::zabbix::server' :}
}
# /FIXME

node /zbxserver0([0-1]+)-([a-z]+)\.vm\.mirantis\.net/ {
  class { '::fuel_project::zabbix::server' :}
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

node 'twin1a-srt.srt.mirantis.net' {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node 'lab-cz.bud.mirantis.net' {
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

node /(osci|review)-(gerrit|tst)([0-9]{0,2})?\.vm\.mirantis\.net/ {
  class { '::fuel_project::gerrit' : }
}

node 'osci-jenkins2.vm.mirantis.net' {
  class { '::fuel_project::common' :
    external_host => true,
  }

  class { '::jenkins::master' :}
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

# *** Anonymous Statistics servers ***
node /(product\-)?stats\.(mirantis\.com|fuel-infra\.org)/ {
  class { '::fuel_project::statistics::analytic' :  }
}

node /collector\.(mirantis\.com|fuel-infra\.org)/ {
  class { '::fuel_project::statistics::collector' : }
}

node /fuel-collect(\-testing)?\.vm\.mirantis\.net/ {
  class { '::fuel_project::statistics::collector' : }
}

node /fuel-stats(\-testing)?\.vm\.mirantis\.net/ {
  class { '::fuel_project::statistics::analytic' : }
}

node /web([0-9]{2,})(-tst)?\.(fuel-infra\.org|vm\.mirantis\.net)/ {
  class { '::fuel_project::web' :}
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

node /ns([0-9]{2})-(bud|kha|mnv|msk|poz|srt)\.devops\.mirantis\.net/ {
  class { '::fuel_project::roles::ns' :}
}

node 'mongo-primary.vm.mirantis.net' {
  class {'::fuel_project::mongo_common':
    primary => true,
  }
}

node 'obs-1.mirantis.com' {
  class { '::obs_server' :}
}

# Test nodes definitions

node 'pxetool.test.local' {
  class { '::fuel_project::puppet::master' :}
  class { '::pxetool' :}
}

node 'slave-01.test.local' {
  class { '::fuel_project::jenkins::slave' :
    run_tests         => true,
    build_fuel_iso    => true,
    fuelweb_iso       => true,
    ldap              => true,
    check_tasks_graph => true,
    fuel_web_selenium => true,
  }
}

node 'slave-02.test.local' {
  class { '::fuel_project::common' :  }
  class { '::jenkins::master' :}
}

node 'slave-03.test.local' {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    ldap                => true,
    build_fuel_plugins  => true,
    jenkins_swarm_slave => true,
    install_docker      => true,
  }
}

node 'slave-04.test.local' {
  class { '::fuel_project::common' :
    external_host => true,
  }
  class { '::fuel_project::seed' :
    external_host                => true,
    apply_firewall_rules         => true,
    tracker_apply_firewall_rules => true,
  }
  class { '::fuel_project::mirror' :
    apply_firewall_rules => true,
  }

  class { '::fuel_project::plugins' :
    apply_firewall_rules => true,
  }

  class { '::fuel_project::updates' :
    apply_firewall_rules => true,
  }
}

node 'slave-05.test.local' {
  class { '::fuel_project::common' :}
  class { '::fuel_project::mirror' :}
}

node 'slave-07.test.local' {
  class { '::fuel_project::jenkins::slave' :
    external_host  => true,
    build_fuel_iso => true,
  }
}

node 'slave-08.test.local' {
  class { '::fuel_project::common' :}
  class { '::zabbix::server' :}
}

node 'slave-09.test.local' {
  class { '::fuel_project::lab_cz' :
    external_host => false,
  }
}

node 'slave-10.test.local' {
  class {'::fuel_project::statistics::collector':
    development => true,
  }
  class {'::fuel_project::statistics::analytic':
    development => true,
  }
}

node 'slave-11.test.local' {
  class {'::fuel_project::statistics::collector':
    development => false,
  }
  class {'::fuel_project::statistics::analytic':
    development => false,
  }
}

node 'slave-12.test.local' {
  class { '::fuel_project::znc' :
    apply_firewall_rules => false,
  }
}

node 'slave-13.test.local' {
  class { '::fuel_project::glusterfs' :  }
}

node 'slave-14.test.local' {
  class { '::fuel_project::glusterfs' :
    create_pool     => true,
    gfs_pool        => [ 'slave-13.test.local','slave-14.test.local' ],
    gfs_volume_name => 'data',
  }
}

node 'slave-15.test.local' {
  class { '::fuel_project::web' :}
}

node 'slave-16.test.local' {
  class { '::fuel_project::common' :
    external_host => false,
  }
  class { '::opentracker' :}
}

node 'slave-17.test.local' {
  class { '::fuel_project::nailgun_demo' :
  }
}

node 'slave-18.test.local' {
  class {'::fuel_project::mongo_common':
    primary => false,
  }
}

node 'slave-19.test.local' {
  class {'::fuel_project::mongo_common':
    primary => false,
  }
}

node 'slave-20.test.local' {
  class {'::fuel_project::mongo_common':
    primary => true,
  }
}

node 'slave-21.test.local' {
  class { '::fuel_project::devops_tools' :}
}

# Sandbox

node /spacewalk([0-9]{2})-sndbx\.vm\.mirantis\.net/ {
  class { '::fuel_project::common' :}
}

node 'jenkins-sandbox.vm.mirantis.net' {
  class { '::fuel_project::jenkins::master' : }
}

node /slave([0-1])([1-2])-sandbox\.vm.mirantis\.net/ {
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
  notify { 'Default node invocation' :}
}
