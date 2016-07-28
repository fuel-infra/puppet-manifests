# Define: ssh::known_host
#
# This class setup known_hosts file on host for particular user.
#
# Parameters:
#   [*hosts*] - hash, contains a hash of hosts which will be affected
#   [*home*] - string, directory where .ssh directory is located
#   [*overwrite*] - bool, delete existing entries in known_hosts file first
#   [*user*] - string, user who owns .ssh directory and known_hosts file
#
define ssh::known_host (
  $hosts,
  $home = "/home/${title}",
  $overwrite = true,
  $user = $title,
) {

  # declare defaults for add_host resources
  $defaults = {
    home => $home,
    user => $user,
  }

  # create .ssh directory
  if (! defined(File["${home}/.ssh"])) {
    file { "${home}/.ssh":
      ensure  => 'directory',
      mode    => '0700',
      owner   => $user,
      require => User[$user],
    }
  }

  # delete known_hosts file first if requested by any function use
  if ($overwrite) {
    if (! defined(File["${home}/.ssh/known_hosts"])) {
      file { "${home}/.ssh/known_hosts":
        ensure  => 'absent',
        require =>  File["${home}/.ssh"],
      }
      # clear known_hosts file before adding new keys
      File["${home}/.ssh/known_hosts"] -> Exec <| tag == 'ssh_keyscan' |>
    }
  }

  # create one or multiple known_host entries
  create_resources('ssh::known_host::add_host', $hosts, $defaults)
}
