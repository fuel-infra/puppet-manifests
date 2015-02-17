# Class: system
#
class system (
  $install_tools = false,
  $mta_aliases = '/etc/aliases',
  $mta_newaliasescmd = '/usr/bin/newaliases',
  $mta_local_only = false,
  $mta_packages = ['postfix'],
  $root_password = undef,
  $root_shell = '/bin/bash',
  $root_email = undef,
  $timezone = undef,
  $tools_packages = ['atop', 'curl', 'htop', 'sysstat']
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
      content => $timezone,
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

    exec { $mta_newaliasescmd :
      command   => $mta_newaliasescmd,
      logoutput => on_failure,
      require   => File[$mta_aliases],
    }

    if($::osfamily == 'Debian') {
      file { '/etc/postfix/main.cf' :
        ensure  => 'present',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('system/main.cf.erb'),
        require => Package[$mta_packages],
        notify  => Service['postfix'],
      }
    }

    service { 'postfix' :
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => Package[$mta_packages],
    }
  }

  if($install_tools) {
    ensure_packages($tools_packages)
  }
}
