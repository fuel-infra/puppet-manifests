# Class: fuel_project::jenkins::slave::custom_scripts
#
# Parameters:
#   [*configs_dir*] - path to global custom script directory with configs
#   [*configs_paths*] - paths to a script configs
#   [*docker_user*] - user which will use docker
#   [*known_hosts*] - known_host entries for docker_user
#

class fuel_project::jenkins::slave::custom_scripts (
  $configs_dir   = '/etc/custom_scripts/',
  $configs_paths = {},
  $docker_user   = 'jenkins',
  $known_hosts   = undef,
) {
  $configs = hiera_hash('fuel_project::jenkins::slave::custom_scripts::configs', {})
  $packages = [
    'git',
  ]

  if (!defined(Class['::fuel_project::common'])) {
    class { '::fuel_project::common' : }
  }

  if (!defined(Class['::jenkins::slave'])) {
    class { '::jenkins::slave' : }
  }

  ensure_packages($packages)

  if ($known_hosts) {
    create_resources('ssh::known_host', $known_hosts, {
      user      => $docker_user,
      overwrite => false,
      require   => User[$docker_user],
    })

  }

  if ($configs) {
    file { $configs_dir :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }

    create_resources(file, $configs_paths, {
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => File[$configs_dir],
    })

    create_resources(file, $configs, {
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => File[$configs_dir],
    })

  }

}
