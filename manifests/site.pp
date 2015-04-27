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
    http_share_iso      => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

# Jenkins Product slave to build documentation
node /docs-slave01.vm.mirantis.net/ {
  class { '::fuel_project::jenkins::slave' :}
}

node /errata([0-9]+)(\-tst)?\.infra\.mirantis\.net/ {
  class { '::fuel_project::roles::errata' :}
}

node /srv(22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37)-bud\.bud\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    http_share_iso      => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node /srv([0-9]{2})-(bud|kha|mnv|msk|poz|srt)\.(devops|infra)\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    http_share_iso      => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node /devops-(01|02)\.mnv\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    http_share_iso      => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}

node /cacher01-(cz|kha|mnv|poz)\.vm\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :}
}

node /(tracker([0-9]{2})-(msk|mnv|bud|srt|kha|poz)\.infra|ctorrent-msk\.msk)\.mirantis\.net/ {
  class { '::fuel_project::roles::tracker' :}
}

node /(seed-(cz|us)1\.fuel-infra\.org)/ {
  hiera_include('classes')
}

node /osci-mirror-(msk|srt|kha|poz)\.(msk|srt|kha|infra)\.mirantis\.net/ {
  class { '::fuel_project::common' :}
  class { '::fuel_project::apps::mirror' :}
}

node /ci-slave([0-9]{2})\.fuel-infra\.org/ {
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

node /infra-ci-slave([0-9]{2})\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::slave' :
    external_host       => true,
  }
}

node /(infra|fuel)-jenkins(\d+)\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::master' :}
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
  class { '::fuel_project::apps::mirror' : }
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

node /zbx(proxy|server)([0-9]+)-([a-z]+)\.(devops|infra|vm)\.mirantis\.net/ {
  hiera_include('classes')
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

node /(osci|review)-(gerrit|tst)([0-9]{0,2})?\.vm\.mirantis\.net/ {
  class { '::fuel_project::gerrit' :
    firewall_enable => true,
  }
}

node /gerrit([0-9]{2})-(msk|bud|srt|kha|poz).fuel-infra.org/ {
  class { '::fuel_project::gerrit' :}
}

node 'docs.fuel-infra.org' {
  class { '::fuel_project::fuel_docs' : }
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

node 'pxetool.test.local' {
  class { '::fuel_project::puppet::master' :}
  class { '::pxetool' :}
}

node /.*\.test\.local/ {
  hiera_include('classes')
}

# Default
node default {
  notify { 'Default node invocation' :}
}
