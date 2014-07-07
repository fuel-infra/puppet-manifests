class jenkins::swarm_slave {
  include dpkg

  include jenkins::params
  include virtual::users

  $packages = $jenkins::params::swarm_packages
  $service = $jenkins::params::service

  $jenkins_master = $jenkins::params::jenkins_master
  $jenkins_user = $jenkins::params::jenkins_user
  $jenkins_password = $jenkins::params::jenkins_password

  $labels = $jenkins::params::labels

  package { $packages :
    ensure => present,
  }

  realize User['jenkins']

  if($::jenkins_update) {
    file { 'jenkins-swarm-slave.conf' :
      path => '/etc/default/jenkins-swarm-slave',
      ensure => present,
      owner => 'root',
      group => 'root',
      mode => '0600',
      content => template('jenkins/swarm_slave.conf.erb')
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

  Class['dpkg']->
    Package[$packages]~>
    Service[$service]
}
