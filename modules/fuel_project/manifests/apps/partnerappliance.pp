# Class: fuel_project::apps::partnerappliance
#
# This class deploys a simple http directory to share files. To upload files
# you have to use rsync+ssh/scp method and upload to 'appliance' user with
# '/var/www/appliance' location. All the files will be available on the
# 'share.fuel-infra.org' address.
#
# Parameters:
#   [*authorized_keys*] - keys authorized to upload data
#   [*group*] - base user group
#   [*home_dir*] - base user home directory path
#   [*data_dir*] - data directory path
#   [*user*] - base user name
#   [*vhost*] - virtual host config name
#   [*service_fqdn*] - FQDN of service
#
class fuel_project::apps::partnerappliance (
  $authorized_keys,
  $group            = 'appliance',
  $home_dir         = '/var/www/appliance',
  $data_dir         = "${home_dir}/data",
  $user             = 'appliance',
  $vhost            = 'appliance',
  $service_fqdn     = "${vhost}.${::domain}",
) {

  # manage user $HOME manually, since we don't need .bash* stuff
  # but only ~/.ssh/
  file { $home_dir :
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => User[$user]
  }

  file { $data_dir :
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [
      File[$home_dir],
    ]
  }

  user { $user :
    ensure     => 'present',
    system     => true,
    managehome => false,
    home       => $home_dir,
    shell      => '/bin/sh',
  }

  $opts = [
    "command=\"rsync --server -rlpt --delete . ${data_dir}\"",
    'no-agent-forwarding',
    'no-port-forwarding',
    'no-user-rc',
    'no-X11-forwarding',
    'no-pty',
  ]

  create_resources(ssh_authorized_key, $authorized_keys, {
    ensure  => 'present',
    user    => $user,
    require => [
      File[$home_dir],
      User[$user],
    ],
    options => $opts,
  })

  ::nginx::resource::vhost { $vhost :
    server_name      => [ $service_fqdn ],
    www_root         => $data_dir,
    vhost_cfg_append => {
      disable_symlinks => 'if_not_owner',
    },
  }
}
