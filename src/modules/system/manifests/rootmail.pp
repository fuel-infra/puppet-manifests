# Class: system::rootmail
#
class system::rootmail (
  $root_email = '',
) {
  include system::params
  $packages = $system::params::rootemail_packages

  $aliases = '/etc/aliases'
  $newaliases = '/usr/bin/newaliases'

  if(!$root_email) {
    fail('system::rootmail invoked with specified email')
  }

  package { $packages :
    ensure      => 'present',
  }

  file { $aliases :
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('system/aliases.erb'),
  }

  exec { $newaliases :
    command   => $newaliases,
    logoutput => on_failure,
  }

  Class['dpkg']->
    Package[$packages]->
    File[$aliases]->
    Exec[$newaliases]
}
