# Used for deployment of TPI lab
class fuel_project::tpi::lab (
  $btsync_secret = $fuel_project::tpi::params::btsync_secret,
  $sudo_commands = [ '/sbin/ebtables', '/sbin/iptables' ],
  $local_home_basenames = [ 'jenkins' ],
) {

  class { '::tpi::nfs_client' :
    local_home_basenames => $local_home_basenames,
  }

  class { '::fuel_project::jenkins::slave' :
    run_tests     => true,
    sudo_commands => $sudo_commands,
    ldap          => true,
  }

  class { '::tpi::vmware_lab' : }

  # these packages will be installed from tpi apt repo defined in hiera
  $tpi_packages = [
    'linux-image-3.13.0-39-generic',
    'linux-image-extra-3.13.0-39-generic',
    'linux-headers-3.13.0-39',
    'linux-headers-3.13.0-39-generic',
    'btsync',
    'sudo-ldap',
    'zsh',
    'most',
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

  file { '/etc/sudoers.d/tpi' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('fuel_project/tpi/tpi.sudoers.d.erb'),
  }

}
