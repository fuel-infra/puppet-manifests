# Class: system::timezone
#
class system::timezone (
  $timezone = 'UTC',
) {

  ensure_packages(['tzdata'])

  file { '/etc/timezone' :
    ensure  => 'present',
    content => $timezone,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { '/etc/localtime' :
    ensure => 'link',
    target => "/usr/share/zoneinfo/${timezone}",
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }
}
