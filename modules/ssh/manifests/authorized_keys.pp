# Class: ssh::authorized_keys
class ssh::authorized_keys {
  $system = hiera_hash('system')

  $root_keys = $system['root_keys']

  create_resources(ssh_authorized_key,
    $root_keys, {
      ensure => present,
      user => 'root'
    }
  )
}
