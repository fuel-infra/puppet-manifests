# Used for deployment of TPI lab
class fuel_project::tpi::lab (
  $btsync_secret = $fuel_project::tpi::params::btsync_secret,
) {

  class { '::fuel_project::jenkins::slave' :
    run_tests      => true,
  }

  # these packages will be installed from tpi apt repo defined in hiera
  $tpi_packages = [
    'linux-image-3.13.0-40-generic',
    'linux-headers-3.13.0-40-generic',
    'btsync',
  ]

  ensure_packages($tpi_packages)

  service { 'btsync':
    ensure  => 'running',
    enable  => true,
    require => Package['btsync'],
  }

  file { '/etc/default/btsync':
    notify  => Service['btsync'],
    mode    => '0600',
    owner   => 'btsync',
    group   => 'btsync',
    content => template('fuel_project/tpi/btsync.erb'),
  }

  file { '/etc/btsync/tpi.conf':
    mode    => '0600',
    owner   => 'btsync',
    group   => 'btsync',
    content => template('fuel_project/tpi/tpi.conf.erb'),
  }

  File['/etc/btsync/tpi.conf']->
    File['/etc/default/btsync']~>
    Service['btsync']
}
