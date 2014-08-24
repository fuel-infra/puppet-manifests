# Class: jenkins::swarm_slave
#
class jenkins::swarm_slave {
  include dpkg

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
    ensure => present,
  }

  realize User['jenkins']

  file { '/etc/default/jenkins-swarm-slave' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('jenkins/swarm_slave.conf.erb')
  }

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  Class['dpkg']->
    Package[$packages]->
    File['jenkins-swarm-slave.conf']~>
    Service[$service]

  File['jenkins-swarm-slave.conf']~>
    Service[$service]

  Class['dpkg']->
    Package[$packages]~>
    Service[$service]
}
