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

  # create authorized_key entry
  ssh_authorized_key { $name:
    ensure => present,
    key    => $key,
    type   => $type,
    user   => $user,
  }
}
