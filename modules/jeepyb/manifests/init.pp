# == Class: jeepyb
#
class jeepyb {
  include mysql::bindings::python

  if ! defined(Package['python-paramiko']) {
    package { 'python-paramiko':
      ensure   => present,
    }
  }

  package { 'gcc':
    ensure => present,
  }

  package{ 'jeepyb':
    ensure  => present,
    require => Class['mysql::bindings::python'],
  }

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  case $::osfamily {
    'Debian': {
      if ! defined(Package['python-yaml']) {
        package { 'python-yaml':
          ensure => present,
        }
        ensure_packages(['python-pip'])
      }
    }
    'RedHat': {
      if ! defined(Package['PyYAML']) {
        package { 'PyYAML':
          ensure => present,
        }
      }
      ensure_packages(['python-pip'])
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jeepyb' module only supports osfamily Debian or RedHat.")
    }
  }
}
