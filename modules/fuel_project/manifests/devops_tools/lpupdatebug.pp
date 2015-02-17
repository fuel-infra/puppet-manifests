# Class fuel_project::devops_tools::lpupdatebug
#
class fuel_project::devops_tools::lpupdatebug (
  $id = '1',
  $consumer_key = '',
  $consumer_secret = '',
  $access_token = '',
  $access_secret = '',
  $appname = 'lpupdatebug',
  $credfile = '/etc/lpupdatebug/credentials.conf',
  $cachedir = '/var/tmp/launchpadlib/',
  $logfile = '/var/log/lpupdatebug.log',
  $host = 'localhost',
  $port = '29418',
  $package_name = 'python-lpupdatebug',
) {

  ensure_packages([$package_name])

  file { '/etc/lpupdatebug/credentials.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('fuel_project/devops_tools/credentials.erb'),
    require => Package['python-lpupdatebug'],
  }

  file { '/etc/lpupdatebug/lpupdatebug.conf':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('fuel_project/devops_tools/lpupdatebug.erb'),
    require => Package['python-lpupdatebug'],
  }

  service { 'lpupdatebug' :
    ensure     => running,
    enable     => true,
    hasrestart => false,
    require    => Package[$package_name]
  }
}
