# Class fuel_project::devops_tools::lpupdatebug
#
# This class deploys lpupdatebug package and it's configuration.
#
# Parameters:
#
#   [*access_token*] - OAuth access token
#   [*access_secret*] - OAuth access token secret
#   [*appname*] - application name
#   [*cachedir*] - directory with cache path
#   [*consumer_key*] - OAuth Consumer key
#   [*consumer_secret*] - OAuth Consumer password
#   [*credfile*] - credentials file path
#   [*env*] - environment name
#   [*host*] - host name for lpupdatebug
#   [*id*] - unique ID used in credentials config file
#   [*logfile*] - log file path
#   [*package_name*] - lpupdatebug package name
#   [*port*] - Gerrit SSH port
#   [*projects*] - Launchpad projects list to parse
#   [*sshprivkey*] - SSH private key path
#   [*sshprivkey_contents*] - SSH private key file contents
#   [*update_status*] - update ticket statuses
#   [*username*] - SSH username
#
class fuel_project::devops_tools::lpupdatebug (
  $access_token = '',
  $access_secret = '',
  $appname = 'lpupdatebug',
  $cachedir = '/var/tmp/launchpadlib/',
  $consumer_key = '',
  $consumer_secret = '',
  $credfile = '/etc/lpupdatebug/credentials.conf',
  $env = 'production',
  $host = 'localhost',
  $id = '1',
  $logfile = '/var/log/lpupdatebug.log',
  $package_name = 'python-lpupdatebug',
  $port = '29418',
  $projects = [],
  $sshprivkey = '/etc/lpupdatebug/lpupdatebug.key',
  $sshprivkey_contents = undef,
  $update_status = 'yes',
  $username = 'lpupdatebug',
) {

  ensure_packages([$package_name])

  if ($sshprivkey_contents)
  {
    file { $sshprivkey :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $sshprivkey_contents,
    }
  }

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

  service { 'python-lpupdatebug' :
    ensure     => running,
    enable     => true,
    hasrestart => false,
    require    => Package[$package_name]
  }

  ensure_packages(['tailnew'])

  zabbix::item { 'lpupdatebug-zabbix-check' :
    content => 'puppet:///modules/fuel_project/devops_tools/userparams-lpupdatebug.conf',
    notify  => Service[$::zabbix::params::agent_service],
    require => Package['tailnew']
  }
}
