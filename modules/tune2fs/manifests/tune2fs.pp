# Define: tune2fs
#
# Parameters:
#   [*action*] - String, taken from $title by default
#     Possible values:
#        $actions = {
#          'mounts_before_check'    => '-c',
#          'set_mount_count'        => '-C',
#          'error_behaviuor'        => '-e',
#          'extended_options'       => '-E',
#          'reserved_blocks_group'  => '-g',
#          'check_interval'         => '-i',
#          'label'                  => '-L',
#          'reserved_percentage'    => '-m',
#          'last_mounted_directory' => '-M',
#          'mount_options'          => '-o',
#          'mmp_check_interval'     => '-p',
#          'reserved_blocks'        => '-r',
#          'quota_options'          => '-Q',
#          'last_checked_time'      => '-T',
#          'reserved_blocks_user'   => '-u',
#          'uuid'                   => '-U',
#        }
#     For detailed information of what each option does please refer
#     to `man tune2fs`
#
#   [*force*] - Boolean, whether or not to add -f option to tune2fs
#   [*value*] - String or Integer, to set for action
#   [*volume*] - String, block device to pass to tune2fs,
#     $title is used by default
#
define tune2fs (
  $action,
  $value,
  $volume = $title,
  $force  = false,
) {
  $actions = {
    'mounts_before_check'    => '-c',
    'set_mount_count'        => '-C',
    'error_behaviuor'        => '-e',
    'extended_options'       => '-E',
    'reserved_blocks_group'  => '-g',
    'check_interval'         => '-i',
    'label'                  => '-L',
    'reserved_percentage'    => '-m',
    'last_mounted_directory' => '-M',
    'mount_options'          => '-o',
    'mmp_check_interval'     => '-p',
    'reserved_blocks'        => '-r',
    'quota_options'          => '-Q',
    'last_checked_time'      => '-T',
    'reserved_blocks_user'   => '-u',
    'uuid'                   => '-U',
  }

  case $::osfamily {
    'Debian': {
      $packages = [
        'e2fsprogs',
      ]
    }
    default: {
      $packages = []
    }
  }

  ensure_packages($packages)

  $args = $actions[$action]
  if($force) {
    $args_force = '-f'
  } else {
    $args_force = ''
  }
  exec { 'apply_tune2fs' :
    command => "/sbin/tune2fs ${args} ${args_force} ${volume}",
    require => Package[$package]
  }
}
