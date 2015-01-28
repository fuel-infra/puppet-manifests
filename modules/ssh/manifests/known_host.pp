# Define: ssh::known_host
#
define ssh::known_host (
  $host = '',
  $port = 22,
  $user = 'root',
  $overwrite = true,
) {
  if $overwrite {
    $cmd = "ssh-keyscan -p ${port} -H ${host} > ~${user}/.ssh/known_hosts"
    $unless = '/bin/false'
  } else {
    $cmd = "ssh-keyscan -p ${port} -H ${host} >> ~${user}/.ssh/known_hosts"
    $unless = "ssh-keygen -F ${host} -f ~${user}/.ssh/known_hosts"
  }
  exec { $cmd:
    user      => $user,
    logoutput => 'on_failure',
    unless    => $unless,
  }
}
