# Class: jenkins::swarm_slave
#
class jenkins::swarm_slave (
  $labels = $::jenkins::params::swarm_labels,
  $master = $::jenkins::params::swarm_master,
  $package = $::jenkins::params::swarm_package,
  $password = $::jenkins::params::swarm_password,
  $service = $::jenkins::params::swarm_service,
  $user = $::jenkins::params::swarm_user,
) inherits ::jenkins::params{
  ensure_packages([$package])

  if (!defined(User['jenkins'])) {
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
      Package[$package],
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
