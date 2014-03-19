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
  $jenkins_master = 'http://jenkins-product.srt.mirantis.net:8080/'
  $jenkins_user = 'fuel-slave-jenkins'
  $jenkins_password = 'l0dasf)aKKswe'
}
