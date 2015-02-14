# Class: gerrit
#
class gerrit (
  $gerrit_listen = '127.0.0.1:8081',
  $gerrit_start_timeout = 90,
  $mysql_host = 'localhost',
  $mysql_database = 'reviewdb',
  $mysql_user = 'gerrit',
  $mysql_password = '',
  $email_private_key = '',
  $service_fqdn = $fqdn,
  $canonicalweburl = '',
  $robots_txt_source = '', # If left empty, the gerrit default will be used.
  $serveradmin = '',
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-gerrit-review.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-gerrit-review.key',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_project_rsa_key_contents = '', # If left empty will not create file.
  $ssh_project_rsa_pubkey_contents = '', # If left empty will not create file.
  $ssh_replication_rsa_key_contents = '', # If left emptry will not create files.
  $ssh_replication_rsa_pubkey_contents = '', # If left emptry will not create files.
  $gerrit_auth_type = 'OPENID_SSO',
  $gerrit_contributor_agreement = true,
  $openidssourl = 'https://login.launchpad.net/+openid',
  $ldap_server = '',
  $ldap_account_base = '',
  $ldap_username = '',
  $ldap_password = '',
  $ldap_account_pattern = '',
  $ldap_account_email_address = '',
  $ldap_sslverify = true,
  $ldap_ssh_account_name = '',
  $ldap_accountfullname = '',
  $email = '',
  $smtpserver = 'localhost',
  $sendemail_from = 'MIXED',
  $database_poollimit = '',
  $container_heaplimit = '',
  $core_packedgitopenfiles = '',
  $core_packedgitlimit = '',
  $core_packedgitwindowsize = '',
  $sshd_threads = '',
  $sshd_listen_address = '*:29418',
  $commentlinks = [],
  $contactstore = false,
  $contactstore_appsec = '',
  $contactstore_pubkey = '',
  $contactstore_url = '',
  $enable_melody = false,
  $melody_session = false,
  $replicate_local = false,
  $replicate_path = '/opt/lib/git',
  $replication = [],
  $gitweb = true,
  $web_repo_url = '',
  $testmode = false,
  $secondary_index = false,
  $secondary_index_type = 'LUCENE',
  $enable_javamelody_top_menu = false,
  $nginx_access_log = '/var/log/nginx/access.log',
  $nginx_error_log = '/var/log/nginx/error.log',
  $nginx_log_format = undef,
) {
  include jeepyb
  include pip

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'gerrit' :
    ensure               => 'present',
    server_name          => [$service_fqdn, $::fqdn],
    rewrite_to_https     => true,
    ssl                  => true,
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

  $gerrit_war = '/var/lib/gerrit/review_site/bin/gerrit.war'
  $gerrit_site = '/var/lib/gerrit/review_site'

  if ($gitweb) {
    if (!defined(Package['gitweb'])) {
      package { 'gitweb' :
        ensure  => 'present',
        require => Class['::nginx'],
      }
    }
  }

  if (!defined(Package['unzip'])) {
    package { 'unzip' :
      ensure => 'present',
    }
  }

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'gerrit':
    ensure  => present,
    require => [
      File['/var/lib/gerrit/review_site/etc/gerrit.config'],
      File['/var/lib/gerrit/review_site/etc/secure.config'],
      File['/var/lib/gerrit/review_site/lib/mysql-connector-java.jar'],
      File['/var/lib/gerrit/review_site/lib/bcprov.jar'],
    ],
  }

  if $external_host {
    firewall { '1000 allow gerrit connections' :
      dport   => ['80', '443', '29418'],
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }

  file { '/var/lib/gerrit/review_site/bin/' :
    ensure  => 'directory',
    recurse => true,
    owner   => 'root',
    group   => 'root',
  }

  file { '/var/lib/gerrit/review_site/bin/gerrit.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('gerrit/gerrit.init.d.erb'),
    require => File['/var/lib/gerrit/review_site/bin/'],
  }

  package { 'openjdk-6-jre-headless':
    ensure  => purged,
    require => Package['openjdk-7-jre-headless'],
  }

  file { '/var/log/gerrit':
    ensure  => 'link',
    target  => '/var/lib/gerrit/review_site/logs',
    require => Package['gerrit'],
  }

  if ((!defined(File['/opt/lib']))
      and ($replicate_path =~ /^\/opt\/lib\/.*$/)) {
    file { '/opt/lib':
      ensure => directory,
      owner  => root,
    }
  }

  # Prepare gerrit directories.  Even though some of these would be created
  # by the init command, we can go ahead and create them now and populate them.
  # That way the config files are already in place before init runs.
  file { [
      '/var/lib/gerrit',
      '/var/lib/gerrit/review_site',
      '/var/lib/gerrit/review_site/etc',
      '/var/lib/gerrit/review_site/static',
      '/var/lib/gerrit/review_site/lib',
      '/var/lib/gerrit/review_site/hooks',
      '/var/lib/gerrit/.ssh',
    ]:
    ensure  => 'directory',
  }

  # Skip replication if we're in test mode
  if ($testmode == false) {
    # Template uses $replication
    file { '/var/lib/gerrit/review_site/etc/replication.config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/replication.config.erb'),
      replace => true,
      require => File['/var/lib/gerrit/review_site/etc'],
    }
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
  file { '/var/lib/gerrit/review_site/etc/gerrit.config':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('gerrit/gerrit.config.erb'),
    replace => true,
    require => File['/var/lib/gerrit/review_site/etc'],
    notify  => Service['gerrit'],
  }

  # Secret files.

  # Gerrit sets these permissions in 'init'; don't fight them.  If
  # these permissions aren't set correctly, gerrit init will write a
  # new secure.config file and lose the mysql password.
  # Template uses $mysql_password, $email_private_key
  file { '/var/lib/gerrit/review_site/etc/secure.config':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('gerrit/secure.config.erb'),
    replace => true,
    require => File['/var/lib/gerrit/review_site/etc'],
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
    file { '/var/lib/gerrit/review_site/static/robots.txt':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => $robots_txt_source,
      require => Package['gerrit'],
    }
  }

  if $ssh_dsa_key_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_host_dsa_key':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_dsa_key_contents,
      replace => true,
      require => Package['gerrit']
    }
  }

  if $ssh_dsa_pubkey_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_host_dsa_key.pub':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_dsa_pubkey_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_rsa_key_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_host_rsa_key':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_rsa_key_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_rsa_pubkey_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_host_rsa_key.pub':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_rsa_pubkey_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_project_rsa_key_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_project_rsa_key':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_project_rsa_key_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_project_rsa_pubkey_contents != '' {
    file { '/var/lib/gerrit/review_site/etc/ssh_project_rsa_key.pub':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_project_rsa_pubkey_contents,
      replace => true,
      require => Package['gerrit'],
    }
  }

  if $ssh_replication_rsa_key_contents != '' {
    file { '/var/lib/gerrit/.ssh/id_rsa':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0600',
      content => $ssh_replication_rsa_key_contents,
      replace => true,
      require => File['/var/lib/gerrit/.ssh']
    }
  }

  if $ssh_replication_rsa_pubkey_contents != '' {
    file { '/var/lib/gerrit/id_rsa.pub':
      owner   => 'gerrit',
      group   => 'gerrit',
      mode    => '0644',
      content => $ssh_replication_rsa_pubkey_contents,
      replace => true,
      require => File['/var/lib/gerrit/.ssh']
    }
  }

  # The init script requires the path to gerrit to be set.
  file { '/etc/default/gerritcodereview':
    ensure  => present,
    source  => 'puppet:///modules/gerrit/gerritcodereview.default',
    replace => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    notify  => Service['gerrit'],
  }

  package { 'libmysql-java':
    ensure  => present,
    require => Package['openjdk-7-jre-headless']
  }

  file { '/var/lib/gerrit/review_site/lib/mysql-connector-java.jar':
    ensure  => link,
    target  => '/usr/share/java/mysql-connector-java.jar',
    require => [
      Package['libmysql-java'],
      File['/var/lib/gerrit/review_site/lib'],
    ],
    notify  => Service['gerrit'],
  }
  file { '/var/lib/gerrit/review_site/lib/mysql-connector-java-5.1.10.jar':
    ensure  => absent,
    require => File['/var/lib/gerrit/review_site/lib/mysql-connector-java.jar'],
    notify  => Service['gerrit'],
  }

  package { 'libbcprov-java':
    ensure  => present,
    require => Package['openjdk-7-jre-headless'],
  }
  file { '/var/lib/gerrit/review_site/lib/bcprov.jar':
    ensure  => link,
    target  => '/usr/share/java/bcprov.jar',
    require => [
      Package['libbcprov-java'],
      File['/var/lib/gerrit/review_site/lib'],
    ],
    notify  => Service['gerrit'],
  }
  file { '/var/lib/gerrit/review_site/lib/bcprov-jdk16-144.jar':
    ensure  => absent,
    require => File['/var/lib/gerrit/review_site/lib/bcprov.jar'],
    notify  => Service['gerrit'],
  }

  # Install Bouncy Castle's OpenPGP plugin and populate the contact store
  # public key file if we're using that feature.
  if ($contactstore == true) {
    package { 'libbcpg-java':
      ensure => present,
    }
    file { '/var/lib/gerrit/review_site/lib/bcpg.jar':
      ensure  => link,
      target  => '/usr/share/java/bcpg.jar',
      require => [
        Package['libbcpg-java'],
        File['/var/lib/gerrit/review_site/lib'],
      ],
    }
    # Template uses $contactstore_pubkey
    file { '/var/lib/gerrit/review_site/etc/contact_information.pub':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('gerrit/contact_information.pub.erb'),
      replace => true,
      require => File['/var/lib/gerrit/review_site/etc'],
    }
  }

  service { 'gerrit' :
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => Package['gerrit']
  }
}
