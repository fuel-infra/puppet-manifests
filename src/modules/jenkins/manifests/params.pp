# Class: jenkins::params
#
class jenkins::params {
  $slave_packages = [
    'openjdk-7-jre-headless'
  ]

  $swarm_packages = [
    'jenkins-swarm-slave'
  ]

  $service = 'jenkins-swarm-slave'
}
