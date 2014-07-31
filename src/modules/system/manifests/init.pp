class system {
  $system = hiera_hash('system')

  class { 'system::rootmail' :
    root_email => $system['root_email'],
  }

  class { 'system::timezone' :
    timezone => $system['timezone']
  }

  include system::tools
  include virtual::packages
  include virtual::users

  $packages = $system::params::packages

  realize Package[$packages]
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
