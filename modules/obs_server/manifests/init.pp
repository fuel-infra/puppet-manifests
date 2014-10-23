# == Class: obs_server
#
# Installs Open Build Service Server on opensuse server.
#
# === Parameters
#
# Do not require any params in the main class.
# All of the possible params are separated on a different classes.
#
# === Variables
#
# All of the variables are stored in hiera

class obs_server {

require obs_server::repo
include obs_server::mysql
include obs_server::nginx

########## packages ##########

Package { ensure => installed }
  package { 'obs-server': }
  package { 'obs-api': }

########## services startup and autorun ##########

  service { 'obsrepserver':
    ensure  => 'running',
    enable  => true,
    require => Package['obs-server'],
  }

  service { 'obssigner':
    ensure  => 'running',
    enable  => true,
    require => File['BSConfig.pm'],
    notify  => Service ['nginx'],
  }

  service { 'obssrcserver':
    ensure  => 'running',
    enable  => true,
    require => Package['obs-server'],
  }

  service { 'obsscheduler':
    ensure  => 'running',
    enable  => true,
    require => File['/srv/www/obs/api/tmp'],
  }

  service { 'obsdispatcher':
    ensure  => 'running',
    enable  => true,
    require => Service['obsscheduler'],
  }

  service { 'obspublisher':
    ensure  => 'running',
    enable  => true,
    require => Service['obsdispatcher'],
  }

  service { 'obsworker':
    ensure  => 'running',
    enable  => true,
    require => File['/srv/www/obs/api/tmp'],
  }

######## configs #############

  file { 'BSConfig.pm':
  ensure  => present,
  path    => '/usr/lib/obs/server/BSConfig.pm',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  force   => true,
  require => Package['obs-server'],
  notify  => Service ['obssigner'],
  content => template('obs_server/BSConfig.pm.erb'),
  }

}
