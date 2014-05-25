class libvirt {
  include libvirt::params

  $packages = $libvirt::params::packages
  $config = $libvirt::params::config
  $default_config = $libvirt::params::default_config
  $service = $libvirt::params::service
  $default_pool_dir = $libvirt::params::default_pool_dir
  $default_pool_name = $libvirt::params::default_pool_name

  package { $packages :
    ensure => latest,
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

  file { '/etc/libvirt/storage' :
    ensure => directory,
  }

  file { "/etc/libvirt/storage/${default_pool_name}.xml" :
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('libvirt/libvirt-pool-default.xml.erb'),
  }

  exec { 'define-default-pool' :
    command => "virsh pool-define /etc/libvirt/storage/${default_pool_name}.xml",
    unless => "virsh pool-list --persistent | awk '{print \$1}' | egrep '^${default_pool_name}\$'"
  }

  exec { 'default-pool-autostart' :
    command => "virsh pool-autostart ${default_pool_name}",
    onlyif => "virsh pool-list --no-autostart | awk '{print \$1}' | egrep '^${default_pool_name}\$'"
  }

  exec { 'default-pool-start' :
    command => "virsh pool-start ${default_pool_name}",
    onlyif => "virsh pool-list --inactive | awk '{print \$1}' | egrep '^${default_pool_name}\$'"
  }

  Class['dpkg']->
    Package[$packages]->
    File['/etc/libvirt/storage']->
    File[$config]->
    File[$default_config]~>
    Service[$service]->
    File["/etc/libvirt/storage/${default_pool_name}.xml"]->
    Exec['define-default-pool']->
    Exec['default-pool-autostart']->
    Exec['default-pool-start']

  Class['dpkg']->
    Package[$packages]~>
    Service[$service]

  File[$config]~>
    Service[$service]

  File[$default_config]~>
    Service[$service]

}
