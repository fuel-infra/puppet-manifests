# Defaults

Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  provider => 'shell',
}

File {
  replace => true,
}

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
    run_tests      => true,
    build_fuel_iso => true,
    fuelweb_iso    => true,
    ldap           => true,
  }
}

node 'ctorrent-msk.msk.mirantis.net' {
  class { '::fuel_project::common' :
    external_host => false,
  }
  class { '::opentracker' :}
}

node /(seed-(cz|us)1\.fuel-infra\.org)/ {
  class { '::fuel_project::seed' :
    external_host                => true,
    apply_firewall_rules         => true,
    tracker_apply_firewall_rules => true,
  }
}

node /(pkgs)?ci-slave([0-9]{2})\.fuel-infra\.org/ {
  class { '::fuel_project::jenkins::slave' :
    external_host       => true,
    run_tests           => true,
    simple_syntax_check => true,
    verify_fuel_web     => true,
    verify_fuel_astute  => true,
    verify_fuel_docs    => true,
  }
}

node /pxe-product-(msk|srt)\.(msk|srt)\.mirantis\.net/ {
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

node 'fuel-puppet.vm.mirantis.net' {
  $firewall = hiera_hash('firewall')
  $puppet = hiera_hash('puppet')

  class { '::fuel_project::puppet::master' :
    apply_firewall_rules   => true,
    external_host          => true,
    firewall_allow_sources => $firewall['known_networks'],
    puppet_server          => $puppet['master'],
  }
}

node 'twin1a-srt.srt.mirantis.net' {
  class { '::fuel_project::jenkins::slave' :
    run_tests => true,
    ldap      => true,
  }
}

node 'lab-cz.bud.mirantis.net' {
  class { '::fuel_project::lab_cz' :
    external_host => false,
  }
}

node 'osci-gerrit.vm.mirantis.net' {
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
  $external_host = true
  class { '::fuel_project::common' :
    external_host => $external_host,
  }

  $params = hiera_hash('osci-jenkins')

  class { '::jenkins::master' :
    service_fqdn                     => $params['service_fqdn'],
    ssl_cert_file_contents           => $params['ssl_cert_file_contents'],
    ssl_key_file_contents            => $params['ssl_key_file_contents'],
    jenkins_ssh_private_key_contents => $params['jenkins_ssh_private_key_contents'],
    jenkins_ssh_public_key_contents  => $params['jenkins_ssh_public_key_contents'],
    jenkins_address                  => $params['jenkins_address'],
    jenkins_java_args                => $params['jenkins_java_args'],
    jjb_username                     => $params['jjb_username'],
    jjb_password                     => $params['jjb_password'],
    apply_firewall_rules             => true,
    firewall_allow_sources           => ['0.0.0.0/0'],
  }
}

node /tpi\d\d\.bud\.mirantis\.net/ {
  class { '::fuel_project::jenkins::slave' :
    run_tests      => true,
  }
}

node 'tpi-puppet.vm.mirantis.net' {
  class { '::fuel_project::puppet::master' :}
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
  class { '::fuel_project::seed' :
    external_host                => true,
    apply_firewall_rules         => true,
    tracker_apply_firewall_rules => true,
    mirror                       => true,
    mirror_apply_firewall_rules  => true,
  }
}

node 'slave-03.test.local' {
  class { '::fuel_project::common' :}
  class { '::zabbix::server' :}
}

node 'slave-04.test.local' {
  class { '::fuel_project::jenkins::slave' :
    external_host       => true,
    run_tests           => true,
    simple_syntax_check => true,
    verify_fuel_web     => true,
    verify_fuel_astute  => true,
    verify_fuel_docs    => true,
  }
}


node 'slave-05.test.local' {
  class { '::fuel_project::jenkins::slave' :
    external_host  => true,
    build_fuel_iso => true,
  }
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

# Default

node default {
  notify { 'Default node invocation' :}
}
