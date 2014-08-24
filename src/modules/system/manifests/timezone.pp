# Class: system::timezone
#
class system::timezone (
  $timezone = 'UTC',
) {
  include virtual::packages

  realize Package['tzdata']

  file { '/etc/timezone' :
    ensure  => 'present',
    content => $timezone,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { '/etc/localtime' :
    ensure => 'present',
    source => "file:///usr/share/zoneinfo/${timezone}",
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }
}
