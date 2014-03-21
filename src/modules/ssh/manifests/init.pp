class ssh {
  include ssh::params

  $root_keys = $ssh::params::root_keys

  create_resources(ssh_authorized_key, $root_keys, {ensure => present, user => 'root'})

  Class['firewall_defaults::pre'] ->
  firewall { '100 allow ssh connections' :
    dport => 22,
    action => 'accept',
  }
}

