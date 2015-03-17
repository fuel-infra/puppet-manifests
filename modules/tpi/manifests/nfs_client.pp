# Used for TPI nfs clients
class tpi::nfs_client (
  $nfs_servers = [ 'tpi-s1', 'tpi-s2' ],
  $local_home_base = '/usr/local/home',
  $local_home_basenames = [],
) {

  ensure_packages('autofs')

  file { $local_home_base:
    ensure => 'directory',
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  localhome { $local_home_basenames:
    local_home_base => $local_home_base,
    require         => File[$local_home_base],
  }

  file { '/etc/auto.master.d':
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => LocalHome[ $local_home_basenames ],
  }

  file { '/etc/auto.master.d/home.autofs':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('tpi/home.autofs.erb'),
    require => File['/etc/auto.master.d']
  }

  file { '/etc/auto.home':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('tpi/auto.home.erb'),
    require => File['/etc/auto.master.d/home.autofs'],
    notify  => Service['autofs'],
  }

  file { '/etc/auto.master.d/direct.autofs':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('tpi/direct.autofs.erb'),
    require => File['/etc/auto.master.d']
  }

  file { '/etc/auto.direct':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('tpi/auto.direct.erb'),
    require => File['/etc/auto.master.d/direct.autofs'],
    notify  => Service['autofs'],
  }

  service{ 'autofs':
    ensure => 'running',
    enable => true
  }

}
