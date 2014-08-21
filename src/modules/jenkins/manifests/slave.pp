class jenkins::slave {
  include virtual::users

  $jenkins = hiera_hash('jenkins')

  if ! defined(Package['openjdk-7-jre-headless']) {
    package { 'openjdk-7-jre-headless' :
      ensure  => present,
      require => Class['dpkg'],
    }
  }

  realize User['jenkins']

  exec { 'ssh_review.openstack.org' :
    command   =>
      'ssh -o StrictHostKeyChecking=no -p 29418 review.openstack.org ; exit 0',
    user      => 'jenkins',
    logoutput => 'on_failure',
    require   => Ssh_authorized_key[keys($jenkins['ssh_keys'])]
  }

  create_resources(ssh_authorized_key, $jenkins['ssh_keys'], {
    ensure  => present,
    user    => 'jenkins',
    require => [ User['jenkins'], Package['openjdk-7-jre-headless'] ]
  })
}
