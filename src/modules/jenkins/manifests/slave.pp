class jenkins::slave {
  include dpkg

  include jenkins::params
  include virtual::users

  $packages = $jenkins::params::slave_packages
  $jenkins_keys = $jenkins::params::jenkins_keys

  package { $packages :
    ensure => present,
  }

  realize User['jenkins']

  exec { 'ssh_review.openstack.org':
    command => 'ssh -o StrictHostKeyChecking=no -p 29418 review.openstack.org ; exit 0',
    user => 'jenkins',
    logoutput => 'on_failure',
  }

  create_resources(ssh_authorized_key, $jenkins_keys, {ensure => present, user => 'jenkins'})

  Class['dpkg']->
    Package[$packages]->
    User['jenkins']->
    Ssh_authorized_key['jenkins@mc0n1-srt']->
    Exec['ssh_review.openstack.org']

  Ssh_Authorized_Key['jenkins@mc0n1-srt']->
    Exec['ssh_review.openstack.org']
}
