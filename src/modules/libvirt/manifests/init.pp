class libvirt {
  include libvirt::params

  $packages = $libvirt::params::packages
  $config = $libvirt::params::config
  $default_config = $libvirt::params::default_config
  $service = $libvirt::params::service
  $default_pool_dir = $libvirt::params::default_pool_dir

  package { $packages :
    ensure => installed,
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

  exec { 'pool-create-default' :
    command => "virsh pool-create-as --name=default --type=dir --target=${default_pool_dir}",
    provider => 'shell',
    user => 'root',
    cwd => '/tmp',
    unless => 'virsh pool-dumpxml default'
  }

  Class['dpkg'] ->
    Package[$packages] -> 
    File[$config] -> 
    File[$default_config] ~> 
    Service[$service] -> 
    Exec['pool-create-default']

  Class['dpkg'] ->
    Package[$packages] ~>
    Service[$service]

  File[$config] ~>
    Service[$service]

  File[$default_config] ~>
    Service[$service]

}
