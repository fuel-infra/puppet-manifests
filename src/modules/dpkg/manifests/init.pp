class dpkg {
  include dpkg::params

  $dpkg_confdir = $dpkg::params::dpkg_confdir
  $init_command = $dpkg::params::init_command

  file { 'allow-unauthenticated.conf' :
    name    => "${dpkg_confdir}/00-allow-unauthenticated.conf",
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dpkg/allow-unauthenticated.conf.erb'),
  }

  exec { $init_command :
    command => $init_command,
    provider => 'shell',
    user => 'root',
    cwd => '/tmp',
  }

  File['allow-unauthenticated.conf'] ->
    Exec[$init_command]
}

