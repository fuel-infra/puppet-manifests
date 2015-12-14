# Class: gerrit::remotes
#
# This simple class sets cron entry which uses jeepyb to fetch remote locations.
# It fetches twice per hour witch randomized time.
#
# Parameters:
#   [*ensure*] - cron entry existance (absent/present)
#
class gerrit::remotes(
  $ensure=present
) {
    cron { 'gerritfetchremotes':
      ensure  => $ensure,
      user    => 'gerrit',
      minute  => [fqdn_rand(30), 30 + fqdn_rand(30)],
      command => '/usr/local/bin/manage-projects',
      require => [Class['jeepyb'], File['/var/lib/jeepyb']],
    }

    file { '/var/lib/jeepyb':
      ensure  => directory,
      owner   => 'gerrit',
      require => User['gerrit'],
    }

    file { '/var/lib/gerrit/remotes.config':
      ensure => absent,
    }
}
