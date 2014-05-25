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

  exec { 'ssh_review.openstack.org':
    command => 'ssh -o StrictHostKeyChecking=no -p 29418 review.openstack.org ; exit 0',
    user => 'jenkins',
    logoutput => 'on_failure',
  }

  Class['dpkg']->
    Package[$packages]->
    User['jenkins']->
    Ssh_authorized_key['jenkins@mc0n1-srt']->
    Exec['ssh_review.openstack.org']

  Ssh_Authorized_Key['jenkins@mc0n1-srt']->
    Exec['ssh_review.openstack.org']
}
