# Class: jeepyb::openstackwatch
#
# This class deploys openstackwatch part of Jeepyb tools.
#
# Parameters:
#
#   [*swift_username*] - username/tenant for swift with 2.0 or just username
#     with 1.0
#   [*swift_password*] - passowrd or api key
#   [*swift_auth_url*] - auth_url of the cluster:
#    for Rackspace this is :
#      https://auth.api.rackspacecloud.com/v1.0
#    or Rackspace UK :
#      https://lon.auth.api.rackspacecloud.com/v1.0
#   [*auth_version*] - auth version:
#     1.0 for Rackspace clouds,
#     2.0 for keystone backend clusters
#   [*projects*] - only show certain projects (openstack/ as start)
#   [*mode*] - allow different mode to output to swift, by default 'combined'
#     will combined all rss in one and 'multiple' will upload all the projects
#     in each rss file.
#   [*container*] - container to upload (probably want to be public)
#   [*feed*] - unused variable
#   [*json_url*] - Json URL where is the gerrit system
#   [*minute*] - CRON entry minute setting
#   [*hour*] - CRON entry hour setting
#
class jeepyb::openstackwatch(
  $swift_username = '',
  $swift_password = '',
  $swift_auth_url = '',
  $auth_version = '',
  $projects = [],
  $mode = 'multiple',
  $container = 'rss',
  $feed = '',
  $json_url = '',
  $minute = '18',
  $hour = '*',
) {
  include jeepyb

  group { 'openstackwatch':
    ensure => present,
  }

  user { 'openstackwatch':
    ensure     => present,
    managehome => true,
    comment    => 'OpenStackWatch User',
    shell      => '/bin/bash',
    gid        => 'openstackwatch',
    require    => Group['openstackwatch'],
  }

  if $swift_password != '' {
    cron { 'openstackwatch':
      ensure  => present,
      command => '/usr/local/bin/openstackwatch /home/openstackwatch/openstackwatch.ini',
      minute  => $minute,
      hour    => $hour,
      user    => 'openstackwatch',
      require => [
        File['/home/openstackwatch/openstackwatch.ini'],
        User['openstackwatch'],
        Class['jeepyb'],
      ],
    }
  }

  file { '/home/openstackwatch/openstackwatch.ini':
    ensure  => present,
    content => template('jeepyb/openstackwatch.ini.erb'),
    owner   => 'root',
    group   => 'openstackwatch',
    mode    => '0640',
    require => User['openstackwatch'],
  }

  if ! defined(Package['python-pyrss2gen']) {
    package { 'python-pyrss2gen':
      ensure => present,
    }
  }

  if ! defined(Package['python-swiftclient']) {
    package { 'python-swiftclient':
      ensure   => present,
    }
  }
}
