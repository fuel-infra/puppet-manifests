class dpkg {
  include dpkg::params

  $dpkg_confdir = $dpkg::params::dpkg_confdir
  file { 'allow-unauthenticated.conf' :
    name    => "${dpkg_confdir}/00-allow-unauthenticated.conf",
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dpkg/allow-unauthenticated.conf.erb'),
  }

  file { 'repos.list' :
    path => '/etc/apt/sources.list.d/repos.list',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('dpkg/repos.list.erb'),
  }
}

