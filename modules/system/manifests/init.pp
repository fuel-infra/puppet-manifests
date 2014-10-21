# Class: system
#
class system {
  $system = hiera_hash('system')

  class { 'system::rootmail' :
    root_email => $system['root_email'],
  }

  class { 'system::timezone' :
    timezone => $system['timezone']
  }

  include system::tools
  include virtual::users

  $packages = $system::params::packages

  each($packages) |$package| {
    if ! defined(Package[$package]) {
      package { $package :
        ensure => installed,
      }
    }
  }
  realize User['root']

  # FIXME: Legacy from IT's puppet agent
  cron { 'puppet' :
    ensure => 'absent',
  }
  cron { 'puppet-timeout' :
    ensure => 'absent',
  }
  cron { 'check-backup' :
    ensure => 'absent',
  }
  # /FIXME
}
