# Class: jenkins::swarm_slave
#
class jenkins::swarm_slave {
  include jenkins::params
  include virtual::users

  $packages = $jenkins::params::swarm_packages
  $service = $jenkins::params::service

  $jenkins = hiera_hash('jenkins')

  $jenkins_master = $jenkins['swarm_server']
  $jenkins_user = $jenkins['swarm_user']
  $jenkins_password = $jenkins['swarm_password']
  $labels = $jenkins['swarm_labels']

  package { $packages :
    ensure  => 'present',
  }

  if ! defined(User['jenkins']) {
    user { 'jenkins' :
      ensure     => 'present',
      name       => 'jenkins',
      shell      => '/bin/bash',
      home       => '/home/jenkins',
      managehome => true,
      system     => true,
      comment    => 'Jenkins',
      groups     => 'www-data',
    }
  }

  file { '/etc/default/jenkins-swarm-slave' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('jenkins/swarm_slave.conf.erb'),
    require => [
      Package[$packages],
      User['jenkins']
    ]
  }~>
  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }
}
