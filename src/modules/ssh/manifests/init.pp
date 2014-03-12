class ssh {
  include ssh::params

  $keys = $ssh::params::keys

  create_resources(ssh_authorized_key, $keys, {ensure => present, user => 'root'})
}

