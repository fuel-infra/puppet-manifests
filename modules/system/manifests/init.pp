# Class: system
#
# This class sets up basic host services and tools.
#
# Parameters:
#   [*install_tools*] - install packages from $tools_packages parameter
#   [*mta_aliases*] - path to mta aliases file
#   [*mta_local_only*] - allow only local e-mails
#   [*mta_newaliasescmd*] - path to mta aliases processing file
#   [*mta_packages*] - packages required to install mta
#   [*root_email*] - e-mail address of root
#   [*root_password*] - root user password
#   [*root_shell*] - root user shell path
#   [*timezone*] - timezone used on host
#   [*tools_packages*] - tools to be installed
#
class system (
  $install_tools     = false,
  $mta_aliases       = '/etc/aliases',
  $mta_local_only    = false,
  $mta_newaliasescmd = '/usr/bin/newaliases',
  $mta_packages      = ['postfix'],
  $root_email        = undef,
  $root_password     = undef,
  $root_shell        = '/bin/bash',
  $timezone          = undef,
  $tools_packages    = ['curl', 'htop', 'sysstat']
) {
  if($root_password) {
    user { 'root' :
      ensure   => 'present',
      shell    => $root_shell,
      password => $root_password,
    }
  }

  if($timezone) {
    ensure_packages(['tzdata'])

    file { '/etc/timezone' :
      ensure  => 'present',
      content => "${timezone}\n",
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    }

    file { '/etc/localtime' :
      ensure => 'link',
      target => "/usr/share/zoneinfo/${timezone}",
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    }
  }

  if($root_email) {
    package { $mta_packages :
      ensure => 'present',
    }

    file { $mta_aliases :
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('system/aliases.erb'),
      require => Package[$mta_packages],
    }

    file { '/etc/mailname' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${::fqdn}\n",
    }

    exec { $mta_newaliasescmd :
      command   => $mta_newaliasescmd,
      logoutput => on_failure,
      require   => File[$mta_aliases],
    }

    if ($mta_local_only) {
      augeas { 'use_mta_locally_only' :
        context => '/files/etc/postfix/main.cf',
        changes => 'set default_transport "error: This server sends mail only locally"',
        require => Package[$mta_packages],
        notify  => Service['postfix'],
      }
    } else {
      augeas { 'use_mta_locally_only' :
        context => '/files/etc/postfix/main.cf',
        changes => 'rm default_transport',
        require => Package[$mta_packages],
        notify  => Service['postfix'],
      }
    }

    service { 'postfix' :
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => [
        Package[$mta_packages],
        File['/etc/mailname'],
      ]
    }
  }

  if($install_tools) {
    ensure_packages($tools_packages)
  }
}
