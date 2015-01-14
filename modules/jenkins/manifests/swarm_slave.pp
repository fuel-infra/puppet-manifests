# Class: jenkins::swarm_slave
#
class jenkins::swarm_slave (
  $labels = $::jenkins::params::swarm_labels,
  $master = $::jenkins::params::swarm_master,
  $package = $::jenkins::params::swarm_package,
  $password = $::jenkins::params::swarm_password,
  $service = $::jenkins::params::swarm_service,
  $java_package = $::jenkins::params::slave_java_package,
  $ssl_cert_file = $::jenkins::params::ssl_cert_file,
  $ssl_cert_file_contents = $::jenkins::params::ssl_cert_file_contents,
  $swarm_service = $::jenkins::params::swarm_service,
  $user = $::jenkins::params::swarm_user,
) inherits ::jenkins::params{

  if (!defined(User['jenkins'])) {
    user { 'jenkins' :
      ensure     => 'present',
      name       => 'jenkins',
      shell      => '/bin/bash',
      home       => '/home/jenkins',
      managehome => true,
      system     => true,
      comment    => 'Jenkins',
    }
  }

  if (!defined(Package[$package])) {
    package { $package :
        ensure  => 'present',
        require => User['jenkins'],
    }
  }

  if (!defined(Package[$java_package])) {
    package { $java_package :
        ensure  => 'present',
    }
  }

  file { '/etc/default/jenkins-swarm-slave' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('jenkins/swarm_slave.conf.erb'),
    require => [
      Package[$package],
      User['jenkins'],
    ],
    notify  => Service[$service],
  }

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  if $ssl_cert_file_contents != '' {

    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
    }

    java_ks { 'jenkins-cert:/etc/ssl/certs/java/cacerts':
      ensure       => latest,
      certificate  => $ssl_cert_file,
      password     => 'changeit',
      trustcacerts => true,
      require      => [
                        File[$ssl_cert_file],
                        Package[$java_package],
                      ],
      notify       => Service[$swarm_service],
    }

  }

}
