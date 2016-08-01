# Class: fuel_project::apps::lpreports
#
# Parameters:
#   [*config_repo*] - String, URL to git repo to clone
#   [*config_branch*] - String, branch in $config_repo to clone.
#     Default: master
#   [*config_target*] - String, target directory to move config files to.
#     Default: /etc/lpreports
#   [*config_tmpdir*] - String, directory to use for scratches while cloning
#     and processing config files.
#     Default: /tmp/lpreports-config
#   [*ssh_key_contents*] - String, SSH private key file content(if needed)
#
class fuel_project::apps::lpreports (
  $config_repo,
  $config_branch    = 'master',
  $config_target    = '/etc/lpreports',
  $config_tmpdir    = '/tmp/lpreports-config',
  $ssh_key_contents = undef,
) {
  include ::lpreports::webapp

  file { '/usr/local/bin/lpreports-config-update.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('fuel_project/apps/lpreports/config-update.sh.erb'),
  }

  cron { 'lpreports-config-update' :
    command => '/usr/bin/timeout -k340 300 /usr/local/bin/lpreports-config-update.sh 2>&1 | logger -t lpreports-config-update',
    user    => 'root',
    hour    => '*/3',
    require => File['/usr/local/bin/lpreports-config-update.sh'],
  }

  if($ssh_key_contents) {
    file { '/var/lib/lpreports/.ssh' :
      ensure => 'directory',
      owner  => 'lpreports',
      group  => 'lpreports',
      mode   => '0500',
    }

    file { '/var/lib/lpreports/.ssh/id_rsa' :
      ensure  => 'present',
      owner   => 'lpreports',
      group   => 'lpreports',
      mode    => '0400',
      content => $ssh_key_contents,
      require => File['/var/lib/lpreports/.ssh'],
    }
  }
}
