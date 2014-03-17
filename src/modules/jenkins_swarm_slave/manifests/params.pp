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
}
