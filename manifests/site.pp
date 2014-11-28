# Defaults

Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  provider => 'shell',
}

File {
  replace => true,
}

Exec['apt_update'] -> Package <| |>

stage { 'pre' :
  before => Stage['main'],
}

# Class definitions

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

node /srv(22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37)-bud\.bud\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    build_fuel_iso      => true,
    fuelweb_iso         => true,
    ldap                => true,
    jenkins_swarm_slave => true,
  }
}


node /cacher01-(cz|kha|mnv|poz)\.vm\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    keep_iso_days => 2,
  }
}

node /jenkins-product-(kha|pl)\.(vm|poz)\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    keep_iso_days => 2,
  }
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

node /build(\d+)\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::slave' :
    external_host  => true,
    build_fuel_iso => true,
  }
}

node 'monitor-product.vm.mirantis.net' {
  class { '::fuel_project::common' :}
  class { '::zabbix::server' :}
}

node /zbxproxy0([0-9]+)-([a-z]+)\.vm\.mirantis\.net/ {
  class { '::fuel_project::common' :}
  class { '::zabbix::proxy' :}
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

node /osci-gerrit(2)?\.vm\.mirantis\.net/ {
  $external_host = true
  $dmz = true

  class { '::fuel_project::common' :
    external_host => $external_host
  }

  include ssh::authorized_keys

  $gerrit = hiera_hash('gerrit')
  $mysql = hiera_hash('mysql')

  class { '::gerrit' :
    gitweb                              => true,
    gerrit_start_timeout                => $gerrit['start_timeout'],
    mysql_host                          => $gerrit['mysql_host'],
    mysql_database                      => $gerrit['mysql_database'],
    mysql_user                          => $gerrit['mysql_user'],
    mysql_password                      => $gerrit['mysql_password'],
    email_private_key                   => $gerrit['email_private_key'],
    ssl_cert_file                       => $gerrit['ssl_cert_file'],
    ssl_cert_file_contents              => $gerrit['ssl_cert_file_contents'],
    ssl_key_file                        => $gerrit['ssl_key_file'],
    ssl_key_file_contents               => $gerrit['ssl_key_file_contents'],
    ssl_chain_file                      => $gerrit['ssl_chain_file'],
    ssl_chain_file_contents             => $gerrit['ssl_chain_file_contents'],
    ssh_dsa_key_contents                => $gerrit['ssh_dsa_key_contents'],
    ssh_dsa_pubkey_contents             => $gerrit['ssh_dsa_pubkey_contents'],
    ssh_rsa_key_contents                => $gerrit['ssh_rsa_key_contents'],
    ssh_rsa_pubkey_contents             => $gerrit['ssh_rsa_pubkey_contents'],
    ssh_project_rsa_key_contents        => $gerrit['project_ssh_rsa_key_contents'],
    ssh_project_rsa_pubkey_contents     => $gerrit['project_ssh_rsa_pubkey_contents'],
    ssh_replication_rsa_key_contents    => $gerrit['replication_ssh_rsa_key_contents'],
    ssh_replication_rsa_pubkey_contents => $gerrit['replication_ssh_rsa_pubkey_contents'],
    contactstore                        => $gerrit['contactstore'],
    service_fqdn                        => $gerrit['service_fqdn'],
    canonicalweburl                     => $gerrit['service_url'],
    container_heaplimit                 => floor($::memorysize_mb/2*1024*1024)
  }

  class { '::gerrit::mysql' :
    mysql_root_password => $mysql['root_password'],
    database_name       => $gerrit['mysql_database'],
    database_user       => $gerrit['mysql_user'],
    database_password   => $gerrit['mysql_password'],
  }
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

node 'tpi-puppet.vm.mirantis.net' {
  class { '::fuel_project::puppet::master' :}
}

# *** Anonymous Statistics servers ***
node 'product-stats.mirantis.com' {
  class {'::fuel_project::statistics::analytic':
    development          => false,
    commercial           => true,
    apply_firewall_rules => true,
  }
}

node 'collector.mirantis.com' {
  class {'::fuel_project::statistics::collector':
    development          => false,
    apply_firewall_rules => true,
  }
}

node 'stats.fuel-infra.org' {
  class {'::fuel_project::statistics::analytic':
    development          => false,
    commercial           => false,
    apply_firewall_rules => true,
  }
}

node 'collector.fuel-infra.org' {
  class {'::fuel_project::statistics::collector':
    development          => false,
    apply_firewall_rules => true,
  }
}

node 'fuel-collect.vm.mirantis.net' {
  class {'::fuel_project::statistics::collector':
    development => false,
  }
}

node 'fuel-stats.vm.mirantis.net' {
  class {'::fuel_project::statistics::analytic':
    development   => false,
  }
}


# Test nodes definitions

node 'pxetool.test.local' {
  class { '::fuel_project::puppet::master' :}
  class { '::pxetool' :}
}

node 'slave-01.test.local' {
  class { '::fuel_project::jenkins::slave' :
    run_tests      => true,
    build_fuel_iso => true,
    fuelweb_iso    => true,
    ldap           => true,
  }
}

node 'slave-02.test.local' {
  class { '::fuel_project::common' :
    external_host => false,
  }
  class { '::opentracker' :}
}

node 'slave-03.test.local' {
  class { '::fuel_project::jenkins::slave' :
    run_tests           => true,
    ldap                => true,
    build_fuel_plugins  => true,
    jenkins_swarm_slave => true,
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

  class { '::fuel_project::updates' :
    apply_firewall_rules => true,
  }
}


node 'slave-05.test.local' {
  class { '::fuel_project::common' :}
  class { '::fuel_project::mirror' :}
}

node 'slave-06.test.local' {
  $external_host = true
  $dmz = true

  class { '::fuel_project::common' :
    external_host => $external_host
  }

  include ssh::authorized_keys

  $gerrit = hiera_hash('gerrit')
  $mysql = hiera_hash('mysql')

  class { '::gerrit' :
    gitweb                              => true,
    gerrit_start_timeout                => $gerrit['start_timeout'],
    mysql_host                          => $gerrit['mysql_host'],
    mysql_database                      => $gerrit['mysql_database'],
    mysql_user                          => $gerrit['mysql_user'],
    mysql_password                      => $gerrit['mysql_password'],
    email_private_key                   => $gerrit['email_private_key'],
    ssl_cert_file                       => $gerrit['ssl_cert_file'],
    ssl_cert_file_contents              => $gerrit['ssl_cert_file_contents'],
    ssl_key_file                        => $gerrit['ssl_key_file'],
    ssl_key_file_contents               => $gerrit['ssl_key_file_contents'],
    ssl_chain_file                      => $gerrit['ssl_chain_file'],
    ssl_chain_file_contents             => $gerrit['ssl_chain_file_contents'],
    ssh_dsa_key_contents                => $gerrit['ssh_dsa_key_contents'],
    ssh_dsa_pubkey_contents             => $gerrit['ssh_dsa_pubkey_contents'],
    ssh_rsa_key_contents                => $gerrit['ssh_rsa_key_contents'],
    ssh_rsa_pubkey_contents             => $gerrit['ssh_rsa_pubkey_contents'],
    ssh_project_rsa_key_contents        => $gerrit['project_ssh_rsa_key_contents'],
    ssh_project_rsa_pubkey_contents     => $gerrit['project_ssh_rsa_pubkey_contents'],
    ssh_replication_rsa_key_contents    => $gerrit['replication_ssh_rsa_key_contents'],
    ssh_replication_rsa_pubkey_contents => $gerrit['replication_ssh_rsa_pubkey_contents'],
    contactstore                        => $gerrit['contactstore'],
    service_fqdn                        => $gerrit['service_fqdn'],
    canonicalweburl                     => $gerrit['service_url'],
    container_heaplimit                 => floor($::memorysize_mb/2*1024*1024)
  }

  class { '::gerrit::mysql' :
    mysql_root_password => $mysql['root_password'],
    database_name       => $gerrit['mysql_database'],
    database_user       => $gerrit['mysql_user'],
    database_password   => $gerrit['mysql_password'],
  }
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
}

node 'slave-11.test.local' {
  class {'::fuel_project::statistics::analytic':
    development => true,
  }
}

node 'slave-12.test.local' {
  class { '::fuel_project::znc' :
    apply_firewall_rules => false,
    service_port         => 7777,
  }
}

# Default

node default {
  notify { 'Default node invocation' :}
}
