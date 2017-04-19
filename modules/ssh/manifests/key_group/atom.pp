# Definition ssh::key_group::atom
#
# Definition of single SSH key single system user pair.
#
define ssh::key_group::atom (
  $key,
  $type,
  $user,
) {
  tag 'key_group_atomic'

  # TODO: upgrade puppet to provide real solution
  if ($user == 'root') {
    $home = '/root'
  } else {
    $home = "/home/${user}"
  }

  # delete authorized_keys before adding keys
  if (! defined(File["purge-${user}-authorized_keys"])) {
    file { "purge-${user}-authorized_keys":
      path   => "${home}/.ssh/authorized_keys",
      ensure => 'absent',
    }
  }

  ## clear known_hosts file before adding new keys
  File["${home}/.ssh/authorized_keys"] -> Ssh_authorized_key <| tag == 'key_group_atomic' |>

  # finally create authorized_key entry
  ssh_authorized_key { $name:
    ensure => present,
    key    => $key,
    type   => $type,
    user   => $user,
  }
}
