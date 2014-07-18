class system::tools {
  include virtual::packages

  file { 'tailnew' :
    path => '/usr/local/bin/tailnew',
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '0755',
    content => template('system/tailnew.erb'),
  }

  realize Package['atop']
  realize Package['curl']
  realize Package['htop']
  realize Package['sysstat']
}
