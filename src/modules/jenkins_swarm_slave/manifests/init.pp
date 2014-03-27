class jenkins_swarm_slave {
  include jenkins_swarm_slave::params

  $packages = $jenkins_swarm_slave::params::packages
  $service = $jenkins_swarm_slave::params::service
  $users = $jenkins_swarm_slave::params::users
  $jenkins_master = $jenkins_swarm_slave::params::jenkins_master
  $jenkins_user = $jenkins_swarm_slave::params::jenkins_user
  $jenkins_password = $jenkins_swarm_slave::params::jenkins_password

  package { $packages :
    ensure => latest,
  }

  create_resources(user, $users, {ensure => present})

  if $::jenkins_update {
    file { 'jenkins-swarm-slave.conf' :
      path => '/etc/default/jenkins-swarm-slave',
      ensure => present,
      owner => 'root',
      group => 'root',
      mode => '0600',
      content => template('jenkins_swarm_slave/jenkins-swarm-slave.conf.erb')
    }

    Class['dpkg']->
      Package[$packages]->
      File['jenkins-swarm-slave.conf']~>
      Service[$service]
    File['jenkins-swarm-slave.conf']~>
      Service[$service]
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Class['dpkg'] -> Package[$packages] ~> Service[$service]
}
