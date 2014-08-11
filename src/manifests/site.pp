# Defaults

Exec {
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  provider => 'shell',
}

File {
  replace => true,
}

stage { 'pre' :
  before => Stage['main'],
}

# Class definitions

class common {
  include dpkg
  include firewall_defaults::pre
  include firewall_defaults::post
  class { '::ntp':
    servers => ['pool.ntp.org'],
    restrict => ['127.0.0.1'],
  }
  include puppet::agent
  include ssh::authorized_keys
  include ssh::sshd
  include system
  include zabbix::agent
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
  class { 'nginx::share' : fuelweb_iso_create => true }
  include ssh::sshd
  include ssh::ldap
}

# Nodes definitions

node /(mc([0-2]+)n([1-8]{1})-(msk|srt)|srv(14|15|16|17|18|19|20|21)-msk)\.(msk|srt)\.mirantis\.net/ {
  class { 'nginx::share' : fuelweb_iso_create => true }
  class { 'fuel_project::jenkins_slave' :
    external_host  => false,
    run_tests => true,
    build_fuel_iso => true,
  }
  include ssh::ldap
}

node 'ctorrent-msk.msk.mirantis.net' {
  include torrent_tracker
}

node /(seed-(cz|us)1\.fuel-infra\.org)/ {
  $external_host = true

  include common
  include nginx
  class { 'nginx::share' : fuelweb_iso_create => true }
  include seed::web
  include torrent_tracker
}

node /(fuel-jenkins([0-9]+)\.mirantis\.com|(pkgs)?ci-slave([0-9]{2})\.fuel-infra\.org)/ {
  $external_host = true

  class { 'fuel_project::jenkins_slave' :
    external_host  => true,
    run_tests      => true,
    build_fuel_iso => false,
  }
}

node /(srv(07|08|11)|jenkins-product)-(msk|srt|kha|pl)\.(msk|srt|vm|poz)\.mirantis\.net/ {
  include srv
  class { 'fuel_project::jenkins_slave' :
    external_host  => false,
    run_tests      => true,
    build_fuel_iso => true,
  }
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
  class { 'fuel_project::jenkins_slave' :
    external_host  => true,
    run_tests      => false,
    build_fuel_iso => true,
  }
}

node 'monitor-product.vm.mirantis.net' {
  include common
  include zabbix::server
}

node 'fuel-puppet.vm.mirantis.net' {
  $external_host = true
  $dmz = true
  $puppet_master = true

  include common
  include puppet::master
}

node 'lab-cz.bud.mirantis.net' {
  include common
  include libvirt
  include ssh::ldap
}

node 'osci-gerrit.vm.mirantis.net' {
  $external_host = true
  $dmz = true

  include common
  include ssh::authorized_keys

  $gerrit = hiera_hash('gerrit')
  $mysql = hiera_hash('mysql')

  class { 'gerrit' :
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

  class { 'gerrit::mysql' :
    mysql_root_password => $mysql['root_password'],
    database_name => $gerrit['mysql_database'],
    database_user => $gerrit['mysql_user'],
    database_password => $gerrit['mysql_password'],
  }
}

node 'test-server' {
  # puppet apply --certname test-server -v -d /etc/puppet/manifests/site.pp

  include virtual::repos

  realize Repository['jenkins']
  realize Repository['docker']
}

node default {
  notify { 'Default node invocation' :}
}
