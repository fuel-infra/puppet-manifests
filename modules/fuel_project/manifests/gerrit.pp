# Class: fuel_project::gerrit
#
class fuel_project::gerrit (
  $external_host = true,
  $dmz = true,
) {
  class { '::fuel_project::common' :
    external_host => $external_host
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

  class { '::hideci' :}
}
