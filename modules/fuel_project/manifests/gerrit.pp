# Class: fuel_project::gerrit
#
class fuel_project::gerrit (
  $dmz = true,
  $firewall_enable = false,
  $replication = [],
  $replication_mode = '',
  $firewall_allow_sources_mysql = {},
  $firewall_allow_sources_bacula = {},

) {

  class { '::fuel_project::common' :
    external_host => $firewall_enable
  }

  $gerrit = hiera_hash('gerrit')
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
    database_name     => $gerrit['mysql_database'],
    database_user     => $gerrit['mysql_user'],
    database_password => $gerrit['mysql_password'],
  }

  class { '::gerrit::hideci' :}

  if $firewall_enable {
    firewall { '1000 allow gerrit connections' :
      dport   => ['80', '443', '29418'],
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }

  if ($replication_mode == 'master') {
    class { '::fuel_project::gerrit::master_config' :}

    file { '/var/lib/gerrit/review_site/etc/replication.config':
      ensure  => present,
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => template('fuel_project/gerrit/replication.config.erb'),
      replace => true,
      require => File['/var/lib/gerrit/review_site/etc'],
    }

    if $firewall_enable {
      include ::firewall_defaults::pre
      create_resources(firewall, $firewall_allow_sources_mysql, {
        ensure  => present,
        dport   => 3306,
        proto   => 'tcp',
        action  => 'accept',
        require => Class['::firewall_defaults::pre'],
      })
    }
  }

  if ($replication_mode == 'slave') {
    class { '::fuel_project::gerrit::slave_config' :}
    class { '::fuel_project::apps::bacula' :}

    if $firewall_enable {
      include ::firewall_defaults::pre
      create_resources(firewall, $firewall_allow_sources_bacula, {
        ensure  => present,
        dport   => 9102,
        proto   => 'tcp',
        action  => 'accept',
        require => Class['::firewall_defaults::pre'],
      })
    }
  }

}
