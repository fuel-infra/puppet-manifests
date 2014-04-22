class jenkins_standalone_slave {
  include dpkg

  include jenkins_standalone_slave::params

  $packages = $jenkins_standalone_slave::params::packages
  $users = $jenkins_standalone_slave::params::users
  $jenkins_keys = $jenkins_standalone_slave::params::jenkins_keys

  package { $packages :
    ensure => latest,
  }

  create_resources(user, $users, {ensure => present})
  create_resources(ssh_authorized_key, $jenkins_keys, {ensure => present, user => 'jenkins'})

  exec { "ssh_review.openstack.org":
    command => "su -c 'ssh -o StrictHostKeyChecking=no -p 29418 review.openstack.org' jenkins; exit 0",
  }
}
