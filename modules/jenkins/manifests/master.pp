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
  $jenkins_api_url = 'http://localhost:8080/',
  $jenkins_api_username = '',
  $jenkins_api_password = '',
  $jenkins_api_token = '',
  $nginx_access_log = '/var/log/nginx/access.log',
  $nginx_error_log = '/var/log/nginx/error.log',
  $nginx_log_format = undef,
  $install_zabbix_item = false,
  $install_label_dumper = false,
  $abel_dumper_destpath = '/var/www/labels',
  # Jenkins auth
  $security_model = 'unsecured',
  $install_groovy = 'yes',
  $ldap_access_group = '',
  $ldap_uri = 'ldap://ldap',
  $ldap_root_dn = 'dc=company,dc=net',
  $ldap_manager_passwd = '',
  $ldap_manager = '',
  $jenkins_cli_file = '/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar',
  $ldap_user_search_base  = '',
  $ldap_group_search_base = '',
  $ldap_user_search = 'uid={0}',
  $ldap_inhibit_root_dn = 'no',
  $jenkins_libdir = '/var/lib/jenkins',
) inherits ::jenkins::params{

  # Install base packages

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'openjdk-6-jre-headless':
    ensure  => purged,
    require => Package['openjdk-7-jre-headless'],
  }

  if($install_groovy) {
    package { 'groovy' :
      ensure => present,
    }
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
    url      => $jenkins_api_url,
    username => $jenkins_api_username,
    password => $jenkins_api_password,
  }

  # Setup nginx

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'jenkins-http' :
    ensure              => 'present',
    listen_port         => 80,
    server_name         => [$service_fqdn, $::fqdn],
    www_root            => '/var/www',
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
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
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
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

  if($install_zabbix_item) {
    file { '/usr/local/bin/jenkins_items.py' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('jenkins/jenkins_items.py.erb'),
    }

    ::zabbix::item { 'jenkins' :
      template => 'jenkins/zabbix_item.conf.erb',
      require  => File['/usr/local/bin/jenkins_items.py'],
    }
  }

  if($install_label_dumper) {
    file { '/usr/local/bin/labeldump.py' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      content => template('jenkins/labeldump.py.erb'),
    }

    cron { 'labeldump-cronjob' :
      command => '/bin/test -f /tmp/jenkins.is.fine && /usr/local/bin/labeldump.py 2>&1 | logger -t labeldump',
      user    => 'root',
      hour    => '*',
      minute  => '*/30',
      require => File['/usr/local/bin/labeldump.py'],
    }

    file { $label_dumper_destpath :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    ::nginx::resource::location { 'labels' :
      ensure   => 'present',
      vhost    => 'jenkins',
      location => basename($label_dumper_destpath),
      www_root => dirname($label_dumper_destpath),
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

  # Prepare groovy script
  file { "${jenkins_libdir}/jenkins_cli.groovy":
    ensure  => present,
    source  => ('puppet:///modules/jenkins/jenkins_cli.groovy'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['groovy'],
  }

  if $security_model == 'ldap' {
    $security_opt_params = join([
      $ldap_access_group,
      $ldap_uri,
      $ldap_root_dn,
      $ldap_user_search,
      $ldap_inhibit_root_dn,
      $ldap_user_search_base,
      $ldap_group_search_base,
      $ldap_manager,
      $ldap_manager_passwd,
    ], ' ')
  }

  # Execute groovy script to setup auth
  exec { 'jenkins_cli.groovy':
    require => [
      File["${jenkins_libdir}/jenkins_cli.groovy"],
      Package['groovy'],
    ],
    command => join([
        '/usr/bin/java',
        "-jar ${jenkins_cli_file}",
        "-s ${jenkins_api_url}",
        "groovy ${jenkins_libdir}/jenkins_cli.groovy",
        'set_security',
        $security_model,
        $security_opt_params,
    ], ' '),
  }
}
