class jenkins_swarm_slave {
  include jenkins_swarm_slave::params

  $packages = $jenkins_swarm_slave::params::packages
  $service = $jenkins_swarm_slave::params::service

  package { $packages :
    ensure => latest,
  }

  file { 'jenkins-swarm-slave.conf' :
    path => '/etc/default/jenkins-swarm-slave',
    ensure => present,
    owner => 'root',
    group => 'root',
    mode => '0600',
    content => template('jenkins_swarm_slave/jenkins-swarm-slave.conf.erb')
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  File['allow-unauthenticated.conf'] -> Package[$packages] -> File['jenkins-swarm-slave.conf'] ~> Service[$service]
  File['allow-unauthenticated.conf'] -> Package[$packages] ~> Service[$service]
  File['jenkins-swarm-slave.conf'] ~> Service[$service]
}
