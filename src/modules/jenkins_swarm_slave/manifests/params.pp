class jenkins_swarm_slave::params {
  $packages = [
    'jenkins-swarm-slave'
  ]
  $service = 'jenkins-swarm-slave'
  $users = {
    'jenkins' => {
      name => 'jenkins',
      shell => '/bin/sh',
      home => '/home/jenkins',
      managehome => true,
      system => true,
      comment => 'Jenkins',
    }
  }
  $jenkins_master = $::jenkins_master
  $jenkins_user = $::jenkins_user
  $jenkins_password = $::jenkins_password

  if $::jenkins_labels {
    $labels = $::jenkins_labels
  } else {
    $labels = "swarm systest ${::operatingsystem}_${::operatingsystemrelease}"
  }
}
