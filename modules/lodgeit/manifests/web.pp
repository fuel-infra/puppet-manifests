# Class: lodgeit::web
#
class lodgeit::web (
  $config            = '/etc/lodgeit/settings.py',
  $database_engine   = 'mysql',
  $database_host     = 'localhost',
  $database_name     = 'lodgeit',
  $database_password = 'lodgeit',
  $database_username = 'lodgeit',
  $debug             = false,
  $group             = 'lodgeit',
  $packages          = [
    'python-lodgeit',
    'python-mysqldb',
  ],
  $secret_key        = '',
  $user              = 'lodgeit',
) {
  ensure_packages($packages)

  user { $user :
    ensure => 'present',
    home   => "/var/lib/${user}",
    shell  => '/usr/sbin/nologin',
    system => true,
  }

  group { $group :
    system => true,
  }

  file { '/etc/lodgeit/settings.yaml' :
    ensure  => 'present',
    owner   => 'lodgeit',
    group   => 'lodgeit',
    mode    => '0700',
    content => template('lodgeit/settings.yaml.erb'),
    require => [
      Package[$packages],
      User[$user],
      Group[$group],
    ],
    notify  => Service['python-lodgeit'],
  }

  service { 'python-lodgeit' :
    ensure => 'running',
    enable => true,
  }
}
