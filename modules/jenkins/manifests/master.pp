# Class: jenkins::master
#
# Parameters:
#   [*jenkins_package_name*] - specify Jenkins package name to install
#   [*jenkins_package_version*] - specify Jenkins package version to install
#   [*jenkins_plugins_package_name*] - specify Jenkins package name to install
#   [*jenkins_plugins_package_version*] - specify Jenkins package version to install
#   [*install_plugins*] - install Jenkins plugins package
#   [*service_fqdn*] - FQDN of Jenkins service
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*firewall_allow_sources*] - sources which are allowed to connect
#   [*jenkins_ssh_private_key_contents*] - jenkins ssh private key contents
#   [*jenkins_ssh_public_key_contents*] - jenkins ssh public key contents
#   [*ssl_cert_file*] - SSL certificate file path
#   [*ssl_cert_file_contents*] - SSL certificate file contents
#   [*ssl_key_file*] - SSL key file path
#   [*ssl_key_file_contents*] - SSL key file contents
#   [*install_zabbix_item*] - install Zabbix agent items for Jenkins
#   [*jenkins_address*] - Jenkins listening IP address
#   [*jenkins_admin_email*] - global configuration of system admin email
#   [*jenkins_java_args*] - Jenkins Java arguments
#   [*jenkins_port*] - Jenkins listening port
#   [*jenkins_proto*] - Jenkins listening protocol
#   [*$markup_formatter*] - markup formatter for Jenkins
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log format
#   [*number_of_executors*] - amount of executors for jenkins master node
#   [*scm_checkout_retry_count*] - retry count for jenkins scm checkout
#   [*theme_css_url*] - URL of Jenkins theme CSS
#   [*theme_js_url*] - URL of Jenkins theme JS
#   [*www_root*] - root web directory path
#   [*install_groovy*] - install Groovy script for Jenkins
#   [*jenkins_cli_file*] - Jenkins cli file path
#   [*jenkins_cli_tries*] - how many tries to run cli file
#   [*jenkins_cli_try_sleep*] - sleep between retries
#   [*jenkins_gearman_enable*] - enable/disable gearman plugin config
#   [*jenkins_gearman_host*] - set the Gearman server's host name
#   [*jenkins_gearman_port*] - set the Gearman server port
#   [*jenkins_libdir*] - path to Jenkins lib directory
#   [*jenkins_management_email*] - management e-mail
#   [*jenkins_management_login*] - management login
#   [*jenkins_management_name*] - managament name
#   [*jenkins_management_password*] - management password
#   [*jenkins_s2m_acl*] - Jenkins security s2m ACL entries
#   [*ldap_access_group*] - LDAP access group
#   [*ldap_group_search_base*] - LDAP group search base
#   [*ldap_inhibit_root_dn*] - LDAP inhibit root DN
#   [*ldap_manager*] - LDAP manager name
#   [*ldap_manager_passwd*] - LDAP manager password
#   [*ldap_overwrite_permissions*] - LDAP overwrite internal permissions
#   [*ldap_root_dn*] - LDAP root DN
#   [*ldap_uri*] - LDAP URI
#   [*ldap_user_search*] - LDAP user search string
#   [*ldap_user_search_base*] - LDAP user search base
#   [*security_model*] - security model used in Jenkins instance
#
class jenkins::master (
  $jenkins_package_name             = 'jenkins',
  $jenkins_package_version          = 'latest',
  $jenkins_plugins_package_name     = 'jenkins-plugins',
  $jenkins_plugins_package_version  = 'latest',
  $install_plugins                  = false,

  $service_fqdn                     = $::fqdn,
  # Firewall access
  $apply_firewall_rules             = false,
  $firewall_allow_sources           = [],
  # Nginx parameters
  # Jenkins user keys
  $jenkins_ssh_private_key_contents = '',
  $jenkins_ssh_public_key_contents  = '',
  $ssl_cert_file                    = $::jenkins::params::ssl_cert_file,
  $ssl_cert_file_contents           = $::jenkins::params::ssl_cert_file_contents,
  $ssl_key_file                     = '/etc/ssl/jenkins.key',
  $ssl_key_file_contents            = '',
  # Jenkins config parameters
  $gerrit_trigger_enabled           = false,
  $install_zabbix_item              = false,
  $jenkins_address                  = '0.0.0.0',
  $jenkins_admin_email              = 'jenkins@example.com',
  $jenkins_gearman_enable           = false,
  $jenkins_gearman_host             = '127.0.0.1',
  $jenkins_gearman_port             = '4730',
  $jenkins_java_args                = '',
  $jenkins_port                     = '8080',
  $jenkins_proto                    = 'http',
  $markup_formatter                 = 'plain-text',
  $nginx_access_log                 = '/var/log/nginx/access.log',
  $nginx_error_log                  = '/var/log/nginx/error.log',
  $nginx_log_format                 = undef,
  $number_of_executors              = '2',
  $scm_checkout_retry_count         = '0',
  $theme_css_url                    = '',
  $theme_js_url                     = '',
  $www_root                         = '/var/www',
  # Jenkins auth
  $install_groovy                   = 'yes',
  $jenkins_cli_file                 = '/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar',
  $jenkins_cli_tries                = '6',
  $jenkins_cli_try_sleep            = '30',
  $jenkins_libdir                   = '/var/lib/jenkins',
  $jenkins_management_email         = '',
  $jenkins_management_login         = '',
  $jenkins_management_name          = '',
  $jenkins_management_password      = '',
  $jenkins_s2m_acl                  = true,
  $ldap_access_group                = '',
  $ldap_group_search_base           = '',
  $ldap_inhibit_root_dn             = 'no',
  $ldap_manager                     = '',
  $ldap_manager_passwd              = '',
  $ldap_overwrite_permissions       = '',
  $ldap_root_dn                     = 'dc=company,dc=net',
  $ldap_uri                         = 'ldap://ldap',
  $ldap_user_search                 = 'uid={0}',
  $ldap_user_search_base            = '',
  $security_model                   = 'unsecured',
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

  package { $jenkins_package_name :
    ensure => $jenkins_package_version,
  }

  if ($jenkins_package_version != 'latest' and $jenkins_package_version != 'present') {
    apt::pin { $jenkins_package_name :
      packages => $jenkins_package_name,
      version  => $jenkins_package_version,
      priority => 1000,
    }
  }

  if($install_plugins) {
    package { $jenkins_plugins_package_name :
      ensure  => $jenkins_plugins_package_version,
      require => Service['jenkins'],
    }

    if ($jenkins_plugins_package_version != 'absent' and
    $jenkins_plugins_package_version != 'latest' and
    $jenkins_plugins_package_version != 'present') {
      apt::pin { $jenkins_plugins_package_name :
        packages => $jenkins_plugins_package_name,
        version  => $jenkins_plugins_package_version,
        priority => 1000,
      }
    }
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

  ensure_resource('user', 'jenkins', {
    ensure     => 'present',
    home       => $jenkins_libdir,
    managehome => true,
  })

  file { "${jenkins_libdir}/.ssh/" :
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => User['jenkins'],
  }

  file { "${jenkins_libdir}/.ssh/id_rsa" :
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => $jenkins_ssh_private_key_contents,
    replace => true,
    require => File["${jenkins_libdir}/.ssh/"],
  }

  file { "${jenkins_libdir}/.ssh/id_rsa.pub" :
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    content => "${jenkins_ssh_public_key_contents} jenkins@${::fqdn}",
    replace => true,
    require => File["${jenkins_libdir}/.ssh"],
  }

  ensure_resource('file', $www_root, {'ensure' => 'directory' })

  # Setup nginx

  include ::nginx

  ::nginx::resource::vhost { 'jenkins-http' :
    ensure              => 'present',
    listen_port         => 80,
    server_name         => [$service_fqdn, $::fqdn],
    www_root            => $www_root,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      return => "301 https://${service_fqdn}\$request_uri",
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
      client_max_body_size   => '8G',
      proxy_intercept_errors => 'on',
      proxy_redirect         => 'off',
      proxy_set_header       => {
        'X-Forwarded-For'   => '$remote_addr',
        'X-Forwarded-Proto' => 'https',
        'X-Real-IP'         => '$remote_addr',
        'Host'              => '$host',
      },
    }
  }

  ::nginx::resource::location { 'static' :
    ensure                => 'present',
    vhost                 => 'jenkins',
    ssl                   => true,
    ssl_only              => true,
    location              => '/static/',
    proxy                 => 'http://127.0.0.1:8080',
    proxy_cache           => 'static',
    proxy_cache_min_uses  => 1,
    proxy_cache_use_stale => 'timeout',
    proxy_cache_valid     => 'any 60m',
    proxy_ignore_headers  => [
      'Cache-Control',
      'Expires',
      'Set-Cookie',
      'X-Accel-Expires',
    ],
    proxy_redirect        => 'off',
    proxy_read_timeout    => 120,
    proxy_set_header      => [
      'X-Forwarded-For $remote_addr',
      'Host $host',
    ],
    location_cfg_append   => {
      proxy_intercept_errors => 'on',
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

  # Backward compability & Cleanup {
  # FIXME: Remove some time after
  cron { 'labeldump-cronjob' :
    ensure => 'absent',
  }
  file { '/usr/local/bin/labeldump.py' :
    ensure  => 'absent',
  }
  # }

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

  if $security_model == 'unsecured' {
    $security_opt_params = 'set_unsecured'
  }

  if $security_model == 'ldap' {
    $security_opt_params = join([
      'set_security_ldap',
      "'${ldap_overwrite_permissions}'",
      "'${ldap_access_group}'",
      "'${ldap_uri}'",
      "'${ldap_root_dn}'",
      "'${ldap_user_search}'",
      "'${ldap_inhibit_root_dn}'",
      "'${ldap_user_search_base}'",
      "'${ldap_group_search_base}'",
      "'${ldap_manager}'",
      "'${ldap_manager_passwd}'",
      "'${jenkins_management_login}'",
      "'${jenkins_management_email}'",
      "'${jenkins_management_password}'",
      "'${jenkins_management_name}'",
      "'${jenkins_ssh_public_key_contents}'",
      "'${jenkins_s2m_acl}'",
    ], ' ')
  }

  if $security_model == 'password' {
    $security_opt_params = join([
      'set_security_password',
      "'${jenkins_management_login}'",
      "'${jenkins_management_email}'",
      "'${jenkins_management_password}'",
      "'${jenkins_management_name}'",
      "'${jenkins_ssh_public_key_contents}'",
      "'${jenkins_s2m_acl}'",
    ], ' ')
  }

  # Execute groovy script to setup auth
  exec { 'jenkins_auth_config':
    require   => [
      File["${jenkins_libdir}/jenkins_cli.groovy"],
      Package['groovy'],
      Service['jenkins'],
    ],
    command   => join([
        '/usr/bin/java',
        "-jar ${jenkins_cli_file}",
        "-s ${jenkins_proto}://${jenkins_address}:${jenkins_port}",
        "groovy ${jenkins_libdir}/jenkins_cli.groovy",
        $security_opt_params,
    ], ' '),
    tries     => $jenkins_cli_tries,
    try_sleep => $jenkins_cli_try_sleep,
    user      => 'jenkins',
  }

  # Execute groovy script to setup global configuration
  exec { 'jenkins_main_config':
    command   => join([
        '/usr/bin/java',
        "-jar ${jenkins_cli_file}",
        "-s ${jenkins_proto}://${jenkins_address}:${jenkins_port}",
        "groovy ${jenkins_libdir}/jenkins_cli.groovy",
        'set_main_configuration',
        "'${jenkins_admin_email}'",
        "'${markup_formatter}'",
        "'${number_of_executors}'",
        "'${scm_checkout_retry_count}'",
    ], ' '),
    tries     => $jenkins_cli_tries,
    try_sleep => $jenkins_cli_try_sleep,
    user      => 'jenkins',
    require   => [
      File["${jenkins_libdir}/jenkins_cli.groovy"],
      Package['groovy'],
      Service['jenkins'],
      Exec['jenkins_auth_config'],
    ],
  }

  exec { 'jenkins_gearman_config':
    command   => join([
        '/usr/bin/java',
        "-jar ${jenkins_cli_file}",
        "-s ${jenkins_proto}://${jenkins_address}:${jenkins_port}",
        "groovy ${jenkins_libdir}/jenkins_cli.groovy",
        'set_gearman',
        $jenkins_gearman_enable,
        $jenkins_gearman_host,
        $jenkins_gearman_port,
    ], ' '),
    tries     => $jenkins_cli_tries,
    try_sleep => $jenkins_cli_try_sleep,
    user      => 'jenkins',
    require   => [
      File["${jenkins_libdir}/jenkins_cli.groovy"],
      Package['groovy'],
      Service['jenkins'],
      Exec['jenkins_auth_config'],
    ],
  }

  # Getting hash from gerrit_trigger_conf
  $gerrit_trigger_conf = hiera_hash('jenkins::master::gerrit_trigger_conf', {})

  # Define: exec_gerrit_conf which runs setup of gerrit configuration
  #
  define exec_gerrit_conf(
    $gerrit_hostname,
    $gerrit_server_name,
    $gerrit_url,
    $gerrit_username,
    $gerrit_key_path,
    $jenkins_address,
    $jenkins_cli_file,
    $jenkins_libdir,
    $jenkins_port,
    $jenkins_proto,
    $review_failed = '0',
    $review_notbuild = '0',
    $review_started = '0',
    $review_successful = '0',
    $review_unstable = '-1',
    $verify_failed = '-1',
    $verify_notbuild = '0',
    $verify_started = '0',
    $verify_successful = '1',
    $verify_unstable = '0'
  ) {
    exec { $gerrit_server_name:
      command   => join([
          '/usr/bin/java',
          "-jar ${jenkins_cli_file}",
          "-s ${jenkins_proto}://${jenkins_address}:${jenkins_port}",
          "groovy ${jenkins_libdir}/jenkins_cli.groovy",
          'setup_gerrit',
          "'${gerrit_hostname}'",
          "'${gerrit_key_path}'",
          "\"'${gerrit_server_name}'\"",
          "'${gerrit_url}'",
          "'${gerrit_username}'",
          "\"'${review_failed}'\"",
          "\"'${review_notbuild}'\"",
          "\"'${review_started}'\"",
          "\"'${review_successful}'\"",
          "\"'${review_unstable}'\"",
          "\"'${verify_failed}'\"",
          "\"'${verify_notbuild}'\"",
          "\"'${verify_started}'\"",
          "\"'${verify_successful}'\"",
          "\"'${verify_unstable}'\"",
      ], ' '),
      tries     => '6',
      try_sleep => '30',
      user      => 'jenkins',
      require   => [
        File["${jenkins_libdir}/jenkins_cli.groovy"],
        Package['groovy'],
        Service['jenkins'],
        Exec['jenkins_auth_config'],
      ],
    }
  }

  if $gerrit_trigger_enabled == true {
    create_resources(exec_gerrit_conf, $gerrit_trigger_conf)
  }

  if ($theme_css_url != '') or ($theme_js_url != '') {
    exec { 'jenkins_theme_config':
      command   => join([
          '/usr/bin/java',
          "-jar ${jenkins_cli_file}",
          "-s ${jenkins_proto}://${jenkins_address}:${jenkins_port}",
          "groovy ${jenkins_libdir}/jenkins_cli.groovy",
          'set_theme',
          "'${theme_css_url}'",
          "'${theme_js_url}'",
      ], ' '),
      tries     => $jenkins_cli_tries,
      try_sleep => $jenkins_cli_try_sleep,
      user      => 'jenkins',
      require   => [
        File["${jenkins_libdir}/jenkins_cli.groovy"],
        Package['groovy'],
        Service['jenkins'],
        Exec['jenkins_auth_config'],
      ],
    }
  }
}
