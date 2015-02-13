# Used for deployment of TPI lab
class fuel_project::tpi::lab (
  $btsync_secret = $fuel_project::tpi::params::btsync_secret,
  $sudo_commands = [ '/sbin/ebtables', '/sbin/iptables' ],
  $nfs_servers = [ 'tpi-s1', 'tpi-s2' ],
) {

  class { '::fuel_project::jenkins::slave' :
    run_tests     => true,
    sudo_commands => $sudo_commands,
    ldap          => true,
  }

  # these packages will be installed from tpi apt repo defined in hiera
  $tpi_packages = [
    'linux-image-3.13.0-39-generic',
    'linux-image-extra-3.13.0-39-generic',
    'linux-headers-3.13.0-39',
    'linux-headers-3.13.0-39-generic',
    'btsync',
    'sudo-ldap',
    'autofs',
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


  # transparent hugepage defragmentation leads to slowdowns
  # in our environments (kvm+vmware workstation), disable it
  file { '/etc/init.d/disable-hugepage-defrag':
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/tpi/disable-hugepage-defrag.erb'),
  }

  service { 'disable-hugepage-defrag':
    ensure  => 'running',
    enable  => true,
    require => File['/etc/init.d/disable-hugepage-defrag'],
  }

  #automount
  file { '/usr/local/jenkins':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  mount { '/usr/local/jenkins':
    ensure  => 'mounted',
    device  => '/home/jenkins',
    fstype  => 'none',
    options => 'rw,bind',
    atboot  => true,
    require => File['/usr/local/jenkins'],
  }

  file { '/etc/auto.master.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Mount['/usr/local/jenkins'],
  }

  file { '/etc/auto.master.d/home.autofs':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/tpi/home.autofs.erb'),
    require => File['/etc/auto.master.d']
  }

  file { '/etc/auto.home':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/tpi/auto.home.erb'),
    require => File['/etc/auto.master.d/home.autofs'],
    notify  => Service['autofs'],
  }

  service{ 'autofs':
    ensure => 'running',
    enable => true
  }

}
