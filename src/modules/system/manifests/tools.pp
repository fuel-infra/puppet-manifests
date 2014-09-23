# Class: system::tols
#
class system::tools {
  file { '/usr/local/bin/tailnew' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('system/tailnew.erb'),
  }

  $packages = ['atop','curl','htop','sysstat']
  ensure_packages($packages)
}
