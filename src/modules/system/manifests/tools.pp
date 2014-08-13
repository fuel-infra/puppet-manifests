class system::tools {
  file { 'tailnew' :
    path => '/usr/local/bin/tailnew',
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '0755',
    content => template('system/tailnew.erb'),
  }

  $packages = ['atop','curl','htop','sysstat']
  each($packages) |$package| {
    if ! defined(Package[$package]) {
      package { $package :
        ensure => installed,
      }
    }
  }
}
