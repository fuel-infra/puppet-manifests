# Class: jenkins::master
#
class jenkins::master (
  $service_fqdn = $::fqdn,
  $install_firewall_rules = false,
  # Nginx parameters
  $ssl_cert_file = '/etc/nginx/jenkins.crt',
  $ssl_key_file = '/etc/nginx/jenkins.key',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  # FIXME: chain certificates are not used in nginx conf right now
  $ssl_chain_file_contents = '',
  # Jenkins user keys
  $jenkins_ssh_private_key_contents = '',
  $jenkins_ssh_public_key_contents = '',
  # Jenkins config parameters
  $jenkins_java_args = '',
  $jenkins_port = '8080',
  $jenkins_address = '0.0.0.0',
  # Jenkins Job Builder
  $jjb_url = 'http://localhost:8080/',
  $jjb_username = '',
  $jjb_password = '',
  ) {

  include virtual::repos
  realize Virtual::Repos::Repository['docker']
  realize Virtual::Repos::Repository['jenkins']

  # Install base packages

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'openjdk-6-jre-headless':
    ensure  => purged,
    require => Package['openjdk-7-jre-headless'],
  }

  package { 'jenkins' :
    ensure => present,
  }

  service { 'jenkins' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  Virtual::Repos::Repository['jenkins'] ~>
  Package['openjdk-7-jre-headless'] ~>
  Package['jenkins'] ~>
  Service['jenkins']

  file { '/etc/default/jenkins':
    ensure  => present,
    mode    => '0644',
    content => template('jenkins/jenkins.erb'),
    require => Package['jenkins'],
  }

  # Setup user
  #
  # FIXME: use virtual::user['jenkins']
  # Currently user and group jenkins created by jenkins package

  file { '/var/lib/jenkins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => $jenkins_ssh_private_key_contents,
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    content => "ssh_rsa ${jenkins_ssh_public_key_contents} jenkins@${::fqdn}",
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  # Add Jenkins Job Builder

  class { '::jenkins::job_builder' :
    url      => $jjb_url,
    username => $jjb_username,
    password => $jjb_password,
  }

  # Setup nginx

  include nginx

  file { '/etc/nginx/sites-available/jenkins.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('jenkins/nginx.conf.erb'),
    require => Class['nginx'],
  }->
  file { '/etc/nginx/sites-enabled/jenkins.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/jenkins.conf',
  }~>
  Service['nginx']

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
      require => Class['nginx'],
      before  => File['/etc/nginx/sites-available/jenkins.conf'],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
      require => Class['nginx'],
      before  => File['/etc/nginx/sites-available/jenkins.conf'],
    }
  }

}
