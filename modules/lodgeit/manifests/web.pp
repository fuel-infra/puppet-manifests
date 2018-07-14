# Class: lodgeit::web
#
# This class deploys lodgeit web part.
#
# Parameters:
#   [*config*] - lodgeit configuration file path
#   [*database_engine*] - database engine
#   [*database_host*] - database hostname
#   [*database_name*] - database name
#   [*database_password*] - database password
#   [*database_username*] - database username
#   [*debug*] - enable debug
#   [*group*] - group used to install application
#   [*packages*] - packages required for this instance
#   [*secret_key*] - application secret key
#   [*user*] - user used to install application
#   [*mode*] - native or uwsgi application mode
#
class lodgeit::web (
  $config            = '/etc/lodgeit/settings.py',
  $database_engine   = 'mysql',
  $database_host     = 'localhost',
  $database_name     = 'lodgeit',
  $database_password = undef,
  $database_username = 'lodgeit',
  $debug             = false,
  $group             = 'lodgeit',
  $packages          = [
    'python-lodgeit',
    'python-mysqldb',
  ],
  $secret_key        = '',
  $user              = 'lodgeit',
  $mode              = 'uwsgi', # native || uwsgi
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

  if ($mode == 'native') {
    service { 'python-lodgeit' :
      ensure => 'running',
      enable => true,
    }
  } else {
    service { 'python-lodgeit' :
      ensure => 'stopped',
      enable => false,
    }

    include ::uwsgi

    ::uwsgi::application { 'lodgeit' :
      plugins  => 'python',
      uid      => $user,
      gid      => $group,
      socket   => '127.0.0.1:4634',
      chdir    => '/usr/share/lodgeit',
      module   => 'wsgi',
      callable => 'application',
      require  => User[$user],
    }
  }
}
