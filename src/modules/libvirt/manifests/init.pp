class libvirt {
  include libvirt::params

  $packages = $libvirt::params::packages
  $config = $libvirt::params::config
  $default_config = $libvirt::params::default_config
  $service = $libvirt::params::service

  package { $packages :
    ensure => latest,
    require => File['allow-unauthenticated.conf'],
  }

  file { $config :
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('libvirt/libvirtd.conf.erb'),
  }

  file { $default_config :
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('libvirt/libvirt-default.erb')
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  File['allow-unauthenticated.conf'] -> Package[$packages] -> File[$config] -> File[$default_config] ~> Service[$service]
  File['allow-unauthenticated.conf'] -> Package[$packages] ~> Service[$service]
  File[$config] ~> Service[$service]
  File[$default_config] ~> Service[$service]

}
