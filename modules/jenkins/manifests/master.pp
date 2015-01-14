# Class: jenkins::master
#
class jenkins::master (
  $service_fqdn = $::fqdn,
  # Firewall access
  $apply_firewall_rules = false,
  $firewall_allow_sources = [],
  # Nginx parameters
  $ssl_cert_file = $::jenkins::params::ssl_cert_file,
  $ssl_cert_file_contents = $::jenkins::params::ssl_cert_file_contents,
  $ssl_key_file = '/etc/ssl/jenkins.key',
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
  ) inherits ::jenkins::params{

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

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'jenkins-http' :
    ensure              => 'present',
    listen_port         => 80,
    www_root            => '/var/www',
    location_cfg_append => {
      rewrite => '^ https://$server_name$request_uri? permanent',
    },
  }
  ::nginx::resource::vhost { 'jenkins' :
    ensure              => 'present',
    listen_port         => 443,
    server_name         => [$service_fqdn, $::fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_cert_file,
    ssl_key             => $ssl_key_file,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    proxy               => 'http://127.0.0.1:8080',
    proxy_read_timeout  => 120,
    location_cfg_append => {
      client_max_body_size => '8G',
      proxy_redirect       => 'off',
      proxy_set_header     => {
        'X-Forwarded-For'   => '$remote_addr',
        'X-Forwarded-Proto' => 'https',
        'X-Real-IP'         => '$remote_addr',
        'Host'              => '$host',
      },
    },
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
      before  => Nginx::Resource::Vhost['jenkins'],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
      before  => Nginx::Resource::Vhost['jenkins'],
    }
  }


  if $apply_firewall_rules {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => [80, 443],
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
