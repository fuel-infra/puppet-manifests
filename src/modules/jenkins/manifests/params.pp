# Class: jenkins::params
#
class jenkins::params {
  $job_builder_packages = [
    'python-jenkins',
    'python-yaml',
  ]

  $slave_authorized_keys = {}
  $slave_java_package = 'openjdk-7-jre-headless'

  $swarm_labels = ''
  $swarm_master = ''
  $swarm_user = ''
  $swarm_password = ''
  $swarm_package = 'jenkins-swarm-slave'
  $swarm_service = 'jenkins-swarm-slave'
}
