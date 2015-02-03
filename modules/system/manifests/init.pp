# Class: system
#
class system (
  $root_password = undef,
  $root_shell = '/bin/bash',
  $timezone = undef,
  $root_email = undef,
  $mta_packages = ['postfix'],
  $aliases = '/etc/aliases',
  $newaliasescmd = '/usr/bin/newaliases',
  $install_tools = false,
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

    file { $aliases :
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('system/aliases.erb'),
      require => Package[$mta_packages],
    }

    exec { $newaliasescmd :
      command   => $newaliasescmd,
      logoutput => on_failure,
      require   => File[$aliases],
    }
  }

  if($install_tools) {
    ensure_packages($tools_packages)
  }
}
