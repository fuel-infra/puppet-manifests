# Define: ssh::known_host::add_host
#
# This class setup particular key of known_hosts file.
#
# Parameters:
#   [*home*] - string, directory where .ssh directory is located
#   [*user*] - string, user who owns .ssh directory and known_hosts file
#   [*hash_hosts*] - bool, wheither to hash hostnames and addresses
#   [*host*] - string, contains host which will be affected
#   [*port*] - string, port where SSH is located on host
#
define ssh::known_host::add_host (
  $home,
  $user,
  $hash_hosts = true,
  $host       = $title,
  $port       = 22,
) {
  if ( $hash_hosts ) {
    $_hash_option = '-H'
  } else {
    $_hash_option = ''
  }
  $cmd = "ssh-keyscan -p ${port} ${_hash_option} ${host} >> ${home}/.ssh/known_hosts"
  $unless = "ssh-keygen -F ${host} -f ${home}/.ssh/known_hosts"

  exec { $cmd:
    user      => $user,
    logoutput => 'on_failure',
    unless    => $unless,
    tag       => 'ssh_keyscan',
  }
}
