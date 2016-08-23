# Defaults

Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  provider => 'shell',
}

File {
  replace => true,
}

stage { 'pre' :
  before => Stage['main'],
}

$gitrevision = '$Id$'

notify { "Revision : ${gitrevision}" :}

file { '/var/lib/puppet' :
  ensure => 'directory',
  owner  => 'puppet',
  group  => 'puppet',
  mode   => '0755',
}

file { '/var/lib/puppet/gitrevision.txt' :
  ensure  => 'present',
  owner   => 'root',
  group   => 'root',
  mode    => '0444',
  content => $gitrevision,
  require => File['/var/lib/puppet'],
}

# Default
node default {
  $classes = hiera('classes', '')
  if ($classes) {
    validate_array($classes)
    hiera_include('classes')
  } else {
    notify { 'Default node invocation' :}
  }
}
