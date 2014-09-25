# Define: ssh::known_host
#
define ssh::known_host (
  $host = '',
  $port = 22,
  $user = 'root',
) {
  exec { "${title}-sync-ssh-keys" :
    command   => "ssh-keyscan -p ${port} -H ${host} > ~${user}/.ssh/known_hosts",
    user      => $user,
    logoutput => 'on_failure',
  }
}
