# Class: gerrit
#
# This class deploys fully functional Gerrit instance with Java and Nginx
# reverse proxy. Multiple extended features are also available like ldap,
# openid support or SSL certificates.
#
# For usage example use please look at 'gerrit' hiera role.
#
# Parameters:
#  [*allow_remote_admin*] - allow remote administration
#  [*cache_web_session_age*] - how long to keep web sessions
#  [*canonicalweburl*] - default URL for Gerrit to be accessed through
#  [*commentlinks*] - comment links are find/replace strings applied to change
#     descriptions, patch comments, in-line code comments and approval category
#     value descriptions to turn set strings into hyperlinks
#  [*contactstore*] - use contact store
#  [*contactstore_appsec*] - a shared secret "password" shared with contact store
#  [*contactstore_pubkey*] - contact store public key
#  [*contactstore_url*] - contact store url
#  [*container_heaplimit*] - java heaplimit setting
#  [*core_packedgitlimit*] - maximum number of bytes to map simultaneously into
#     memory from pack files
#  [*core_packedgitopenfiles*] - maximum number of pack files to have open at once
#  [*core_packedgitwindowsize*] - number of bytes of a pack file to load into
#     memory in a single read operation
#  [*database_poollimit*] - maximum number of open database connections
#  [*default_max_clause_count*] - index maximum number of clauses
#  [*email*] - default email to be used by Gerrit
#  [*email_private_key*] - private key used to sign emails
#  [*enable_javamelody_top_menu*] - enable top menu of javamelody plugin
#  [*enable_melody*] - enable javamelody plugin
#  [*gerrit_auth_type*] - authorization type used by Gerrit
#  [*gerrit_contributor_agreement*] - contributor agreemenet for Gerrit
#  [*gerrit_listen*] - listening address of Gerrit
#  [*gerrit_site*] - Gerrit site environment values
#  [*gerrit_start_timeout*] - init script Gerrit starting timeout
#  [*gitweb*] - use gitweb
#  [*ldap_account_base*] - ldap authorization account base value
#  [*ldap_account_email_address*] - ldap authorization email address value
#  [*ldap_account_pattern*] - ldap authorization pattern value
#  [*ldap_accountfullname*] - ldap authorization full name value
#  [*ldap_password*] - ldap authorization password
#  [*ldap_server*] - ldap authorization server
#  [*ldap_ssh_account_name*] - ldap authorization account name
#  [*ldap_sslverify*] - ldap ssl verification
#  [*ldap_username*] - ldap authorzation username
#  [*ldap_groupbase*] - ldap groupbase
#  [*ldap_grouppattern*] - ldap group pattern
#  [*ldap_groupmemberpattern*] - ldap member pattern
#  [*melody_session*] - enable session data collection for melody
#  [*mysql_database*] - MySQL database name used by Gerrit
#  [*mysql_host*] - MySQL host used by Gerrit
#  [*mysql_password*] - MySQL password used by Gerrit
#  [*mysql_user*] - MySQL user used by Gerrit
#  [*nginx_access_log*] - nginx access log path
#  [*nginx_error_log*] - nginx error log path
#  [*nginx_log_format*] - nginx log format
#  [*openidssourl*] - SSO url used by OpenID
#  [*replicate_local*] - unused value
#  [*replicate_path*] - replication path
#  [*replication*] - unused value
#  [*robots_txt_source*] - robots.txt file source
#  [*secondary_index*] - use secondary index
#  [*secondary_index_type*] - secondary index type
#  [*sendemail_from*] - sendemail 'from' setting
#  [*serveradmin*] - unused value
#  [*service_fqdn*] - Gerrit service FQDN
#  [*smtpserver*] - smtp server to use
#  [*ssh_dsa_key_contents*] - ssh dsa key contents
#  [*ssh_dsa_pubkey_contents*] - ssh dsa pubkey contents
#  [*ssh_project_rsa_key_contents*] - ssh project rsa key contents
#  [*ssh_project_rsa_pubkey_contents*] - ssh project rsa pubkey contents
#  [*ssh_replication_rsa_key_contents*] - ssh replication rsa key contents
#  [*ssh_replication_rsa_pubkey_contents*] - ssh replication rsa pubkey contents
#  [*ssh_rsa_key_contents*] - ssh rsa key contents
#  [*ssh_rsa_pubkey_contents*] - ssh rsa pubkey contents
#  [*sshd_listen_address*] - sshd daemon listening address
#  [*sshd_threads*] - sshd threads to start
#  [*ssl_cert_file*] - ssl certificate file path
#  [*ssl_cert_file_contents*] - ssl certiticate file contents
#  [*ssl_chain_file*] - ssl chain file path
#  [*ssl_chain_file_contents*] - ssl chain file contents
#  [*ssl_key_file*] - ssl key file path
#  [*ssl_key_file_contents*] - ssl key file contents
#  [*web_repo_url*] - gitweb url
#
class gerrit (
  $allow_remote_admin                  = false,
  $cache_web_session_age               = '1d',
  $canonicalweburl                     = '',
  $commentlinks                        = [],
  $contactstore                        = false,
  $contactstore_appsec                 = '',
  $contactstore_pubkey                 = '',
  $contactstore_url                    = '',
  $container_heaplimit                 = '',
  $core_packedgitlimit                 = '',
  $core_packedgitopenfiles             = '',
  $core_packedgitwindowsize            = '',
  $database_poollimit                  = '',
  $default_max_clause_count            = 1024,
  $email                               = '',
  $email_private_key                   = '',
  $enable_javamelody_top_menu          = false,
  $enable_melody                       = false,
  $gerrit_auth_type                    = 'OPENID_SSO',
  $gerrit_contributor_agreement        = true,
  $gerrit_listen                       = '127.0.0.1:8081',
  $gerrit_site                         = '/var/lib/gerrit/review_site',
  $gerrit_start_timeout                = 90,
  $gitweb                              = true,
  $ldap_account_base                   = '',
  $ldap_account_email_address          = '',
  $ldap_account_pattern                = '',
  $ldap_accountfullname                = undef,
  $ldap_password                       = undef,
  $ldap_server                         = '',
  $ldap_ssh_account_name               = '',
  $ldap_sslverify                      = undef,
  $ldap_username                       = undef,
  $ldap_groupbase                      = undef,
  $ldap_grouppattern                   = undef,
  $ldap_groupmemberpattern             = undef,
  $melody_session                      = false,
  $mysql_database                      = 'reviewdb',
  $mysql_host                          = 'localhost',
  $mysql_password                      = '',
  $mysql_user                          = 'gerrit',
  $nginx_access_log                    = '/var/log/nginx/access.log',
  $nginx_error_log                     = '/var/log/nginx/error.log',
  $nginx_log_format                    = undef,
  $openidssourl                        = 'https://login.launchpad.net/+openid',
  $replicate_local                     = false,
  $replicate_path                      = '/opt/lib/git',
  $replication                         = [],
  $robots_txt_source                   = '', # If left empty, the gerrit default will be used.
  $secondary_index                     = false,
  $secondary_index_type                = 'LUCENE',
  $sendemail_from                      = 'MIXED',
  $serveradmin                         = '',
  $service_fqdn                        = $fqdn,
  $smtpserver                          = 'localhost',
  $ssh_dsa_key_contents                = '', # If left empty puppet will not create file.
  $ssh_dsa_pubkey_contents             = '', # If left empty puppet will not create file.
  $ssh_project_rsa_key_contents        = '', # If left empty will not create file.
  $ssh_project_rsa_pubkey_contents     = '', # If left empty will not create file.
  $ssh_replication_rsa_key_contents    = '', # If left empty will not create files.
  $ssh_replication_rsa_pubkey_contents = '', # If left empty will not create files.
  $ssh_rsa_key_contents                = '', # If left empty puppet will not create file.
  $ssh_rsa_pubkey_contents             = '', # If left empty puppet will not create file.
  $sshd_listen_address                 = '*:29418',
  $sshd_threads                        = '',
  $ssl_cert_file                       = '/etc/ssl/certs/ssl-cert-gerrit-review.pem',
  $ssl_cert_file_contents              = '', # If left empty puppet will not create file.
  $ssl_chain_file                      = '',
  $ssl_chain_file_contents             = '', # If left empty puppet will not create file.
  $ssl_key_file                        = '/etc/ssl/private/ssl-cert-gerrit-review.key',
  $ssl_key_file_contents               = '', # If left empty puppet will not create file.
  $web_repo_url                        = '',
) {
  include ::jeepyb
  include ::nginx

  ::nginx::resource::vhost { 'gerrit' :
    ensure               => 'present',
    server_name          => [$service_fqdn, $::fqdn],
    rewrite_to_https     => true,
    ssl                  => true,
    ssl_port             => 443,
    ssl_cert             => $ssl_cert_file,
    ssl_key              => $ssl_key_file,
    ssl_cache            => 'shared:SSL:10m',
    ssl_session_timeout  => '10m',
    proxy                => 'http://127.0.0.1:8081',
    access_log           => $nginx_access_log,
    error_log            => $nginx_error_log,
    format_log           => $nginx_log_format,
    use_default_location => false,
  }

  ::nginx::resource::location { 'gerrit-proxy' :
    ensure             => 'present',
    vhost              => 'gerrit',
    ssl                => true,
    ssl_only           => true,
    location           => '/',
    proxy              => 'http://127.0.0.1:8081',
    proxy_redirect     => 'off',
    proxy_read_timeout => 120,
    proxy_set_header   => [
      'X-Forwarded-For $remote_addr',
      'Host $host',
    ],
  }

  ::nginx::resource::location { 'gerrit-static' :
    ensure                => 'present',
    vhost                 => 'gerrit',
    ssl                   => true,
    ssl_only              => true,
    location              => '~* \.cache\.(html|gif|png|css|jar|swf|js)$',
    proxy                 => 'http://127.0.0.1:8081',
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
  }

  ::nginx::resource::location { 'custom-static' :
    ensure   => 'present',
    vhost    => 'gerrit',
    ssl      => true,
    ssl_only => true,
    location => '/static/',
    www_root => $gerrit_site,
  }

  user { 'gerrit' :
    ensure     => 'present',
    name       => 'gerrit',
    shell      => '/bin/false',
    home       => '/var/lib/gerrit',
    managehome => true,
    comment    => 'Gerrit',
  }

  $java_home = $::lsbdistcodename ? {
    'precise' => '/usr/lib/jvm/java-7-openjdk-amd64/jre',
    'trusty'  => '/usr/lib/jvm/java-7-openjdk-amd64/jre',
  }

  if ($gitweb) {
    if (!defined(Package['gitweb'])) {
      package { 'gitweb' :
        ensure  => 'present',
        require => Class['::nginx'],
        before  => Package['gerrit'],
      }
    }
  }

  if (!defined(Package['unzip'])) {
    package { 'unzip' :
      ensure => 'present',
    }
  }

  package { 'openjdk-7-jre-headless' :
    ensure => 'present',
  }

  package { 'gerrit' :
    ensure  => 'present',
    require => [
      File["${gerrit_site}/etc/gerrit.config"],
      File["${gerrit_site}/etc/secure.config"],
      File["${gerrit_site}/lib/mysql-connector-java.jar"],
      File["${gerrit_site}/lib/bcprov.jar"],
    ],
  }

  file { "${gerrit_site}/bin/" :
    ensure  => 'directory',
    recurse => true,
    owner   => 'root',
    group   => 'root',
  }

  file { "${gerrit_site}/bin/gerrit.sh" :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('gerrit/gerrit.init.d.erb'),
    require => File["${gerrit_site}/bin/"],
  }

  package { 'openjdk-6-jre-headless' :
    ensure  => 'purged',
    require => Package['openjdk-7-jre-headless'],
  }

  file { '/var/log/gerrit' :
    ensure  => 'link',
    target  => "${gerrit_site}/logs",
    require => Package['gerrit'],
  }

  if ((!defined(File['/opt/lib']))
      and ($replicate_path =~ /^\/opt\/lib\/.*$/)) {
    file { '/opt/lib':
      ensure => 'directory',
      owner  => 'root',
    }
  }

  # Prepare gerrit directories.  Even though some of these would be created
  # by the init command, we can go ahead and create them now and populate them.
  # That way the config files are already in place before init runs.
  file { [
      $gerrit_site,
      "${gerrit_site}/etc",
      "${gerrit_site}/static",
      "${gerrit_site}/lib",
      "${gerrit_site}/hooks",
      '/var/lib/gerrit',
      '/var/lib/gerrit/.ssh',
    ]:
    ensure => 'directory',
    owner  => 'gerrit',
    group  => 'gerrit',
  }

  # Gerrit sets these permissions in 'init'; don't fight them.
  # Template uses:
  # - $mysql_host
  # - $canonicalweburl
  # - $database_poollimit
  # - $gerrit_contributor_agreement
  # - $gerrit_auth_type
  # - $openidssourl
  # - $ldap_server
  # - $ldap_username
  # - $ldap_password
  # - $ldap_account_base
  # - $ldap_account_pattern
  # - $ldap_account_email_address
  # - $smtpserver
  # - $sendmail_from
  # - $java_home
  # - $container_heaplimit
  # - $core_packedgitopenfiles
  # - $core_packedgitlimit
  # - $core_packedgitwindowsize
  # - $sshd_listen_address
  # - $sshd_threads
  # - $httpd_maxwait
  # - $httpd_acceptorthreads
  # - $httpd_minthreads
  # - $httpd_maxthreads
  # - $commentlinks
  # - $enable_melody
  # - $melody_session
  # - $gitweb
  # - $contactstore_appsec
  # - $contactstore_url
  file { "${gerrit_site}/etc/gerrit.config" :
    ensure  => 'present',
    owner   => 'gerrit',
    group   => 'gerrit',
    mode    => '0644',
    content => template('gerrit/gerrit.config.erb'),
    replace => true,
    require => File["${gerrit_site}/etc"],
    notify  => Service['gerrit'],
  }

  # Secret files.

  # Gerrit sets these permissions in 'init'; don't fight them.  If
  # these permissions aren't set correctly, gerrit init will write a
  # new secure.config file and lose the mysql password.
  # Template uses $mysql_password, $email_private_key
  file { "${gerrit_site}/etc/secure.config" :
    ensure  => 'present',
    owner   => 'gerrit',
    group   => 'gerrit',
    mode    => '0600',
    content => template('gerrit/secure.config.erb'),
    replace => true,
    require => File["${gerrit_site}/etc"],
    notify  => Service['gerrit'],
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => [
        File['/etc/nginx/sites-enabled/gerrit.conf'],
        Nginx::Resource::Vhost['gerrit'],
      ],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
      before  => [
        File['/etc/nginx/sites-enabled/gerrit.conf'],
        Nginx::Resource::Vhost['gerrit'],
      ],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_chain_file_contents,
      before  => [
        File['/etc/nginx/sites-enabled/gerrit.conf'],
        Nginx::Resource::Vhost['gerrit'],
      ],
    }
  }

  if $robots_txt_source != '' {
    file { "${gerrit_site}/static/robots.txt" :
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => $robots_txt_source,
      require => Package['gerrit'],
    }
  }

  if $ssh_dsa_key_contents != '' {
    file { "${gerrit_site}/etc/ssh_host_dsa_key" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_dsa_key_contents,
      replace => true,
      require => File[$gerrit_site],
      before  => Package['gerrit'],
    }
  }

  if $ssh_dsa_pubkey_contents != '' {
    file { "${gerrit_site}/etc/ssh_host_dsa_key.pub" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_dsa_pubkey_contents,
      replace => true,
      require => File[$gerrit_site],
      before  => Package['gerrit'],
    }
  }

  if $ssh_rsa_key_contents != '' {
    file { "${gerrit_site}/etc/ssh_host_rsa_key" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_rsa_key_contents,
      replace => true,
      require => File[$gerrit_site],
      before  => Package['gerrit'],
    }
  }

  if $ssh_rsa_pubkey_contents != '' {
    file { "${gerrit_site}/etc/ssh_host_rsa_key.pub" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_rsa_pubkey_contents,
      replace => true,
      require => File[$gerrit_site],
      before  => Package['gerrit'],
    }
  }

  if $ssh_project_rsa_key_contents != '' {
    file { "${gerrit_site}/etc/ssh_project_rsa_key" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_project_rsa_key_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_project_rsa_pubkey_contents != '' {
    file { "${gerrit_site}/etc/ssh_project_rsa_key.pub" :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_project_rsa_pubkey_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_replication_rsa_key_contents != '' {
    file { '/var/lib/gerrit/.ssh/id_rsa' :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_replication_rsa_key_contents,
      replace => true,
      require => File['/var/lib/gerrit/.ssh']
    }
  }

  if $ssh_replication_rsa_pubkey_contents != '' {
    file { '/var/lib/gerrit/id_rsa.pub' :
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_replication_rsa_pubkey_contents,
      replace => true,
      require => File['/var/lib/gerrit/.ssh']
    }
  }

  # The init script requires the path to gerrit to be set.
  file { '/etc/default/gerritcodereview' :
    ensure  => 'present',
    content => template('gerrit/gerritcodereview.default.erb'),
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Service['gerrit'],
  }

  package { 'libmysql-java' :
    ensure  => 'present',
    require => Package['openjdk-7-jre-headless']
  }

  file { "${gerrit_site}/lib/mysql-connector-java.jar" :
    ensure  => 'link',
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [
      Package['libmysql-java'],
      File["${gerrit_site}/lib"],
    ],
    notify  => Service['gerrit'],
  }
  # we can freely remove this custom jar, since out-of-the-box
  # mysql-connector-java-5.1.28.jar is used
  file { "${gerrit_site}/lib/mysql-connector-java-5.1.21.jar" :
    ensure  => 'absent',
    require => File["${gerrit_site}/lib/mysql-connector-java.jar"],
    notify  => Service['gerrit'],
  }

  package { 'libbcprov-java' :
    ensure  => 'present',
    require => Package['openjdk-7-jre-headless'],
  }
  file { "${gerrit_site}/lib/bcprov.jar" :
    ensure  => 'link',
    target  => '/usr/share/java/bcprov.jar',
    require => [
      Package['libbcprov-java'],
      File["${gerrit_site}/lib"],
    ],
    notify  => Service['gerrit'],
  }
  file { "${gerrit_site}/lib/bcprov-jdk16-144.jar" :
    ensure  => 'absent',
    require => File["${gerrit_site}/lib/bcprov.jar"],
    notify  => Service['gerrit'],
  }

  # Install Bouncy Castle's OpenPGP plugin and populate the contact store
  # public key file if we're using that feature.
  if ($contactstore == true) {
    package { 'libbcpg-java' :
      ensure => 'present',
    }
    file { "${gerrit_site}/lib/bcpg.jar" :
      ensure  => 'link',
      target  => '/usr/share/java/bcpg.jar',
      require => [
        Package['libbcpg-java'],
        File["${gerrit_site}/lib"],
      ],
    }
    # Template uses $contactstore_pubkey
    file { "${gerrit_site}/etc/contact_information.pub" :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/contact_information.pub.erb'),
      replace => true,
      require => File["${gerrit_site}/etc"],
    }
  }

  service { 'gerrit' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => Package['gerrit']
  }
}
