# Class qa_reporting::application
#
# This class configures application and database for QA-reporting portal
#
#  [*admin_password*] - the application's admin password
#  [*admin_users*] - the application's admin users
#  [*google_app_domain*] - domain to specify Google's credentials
#  [*google_key*] - application key, generated on Google's side
#  [*google_secret*] - secret key for the Google's application
#  [*jira_user*] - Jira user to get access there
#  [*jira_password*] - Jira user's password
#  [*launchpad_consumer_key*] - Launchpad's consumer key
#  [*launchpad_oauth_access_token*] - Launchpad's access token
#  [*launchpad_oauth_access_token_secret*] - Launchpad's access token's secret
#  [*lpreports_api_url*] - url to get data from LP Reports service
#  [*lpreports_auth_token*] - LP Reports token to get access
#  [*mail_password*] - mail user's password
#  [*mail_username*] - mail user's login to send notifications
#  [*testrail_baseurl*] - link to a Testrail service
#  [*testrail_user*] - Testrail user
#  [*testrail_password*] - Testrail user's password
#  [*app_user*] - system user to run qareporting portal by uwsgi
#  [*app_path*] - path where the application is installed, this link is used
#    to make some changes there
#  [*credential_file*] - path to file with the application's credentials
#  [*credential_store*] - directory to store the application-related data
#  [*credential_store_template*] - template to file $credential file
#  [*gzip_types*] - archiving items are used by nginx for the application
#  [*logdir*] - path to directory with uwsgi logs
#  [*modules_path*] - path to directory where npm's modules will be installed
#  [*modules_path_template*] - path to file with data for npm
#  [*nginx_access_log*] -  path to nginx access logs
#  [*nginx_error_log*] - path to nginx error logs
#  [*nginx_log_format*] - definition of nginx logs format
#  [*nginx_server_name*] - nginx server name
#  [*package*] - the application package name
#  [*python_path*] - path to Python 3 interpretator
#  [*ssl_certificate*] - path to SSL-certificate
#  [*ssl_certificate_contents*] - SSL-certificate body
#  [*ssl_key*] - path to SSL-key
#  [*ssl_key_contents*] - SSL-key body
#  [*static_folder*] - path to a directory with static data
#  [*static_path*] - path to a directory with npm's build cache
#  [*uwsgi_chdir*] - uwsgi working directory
#  [*webpack_manifest_path*] - path to webpack config file

class qa_reporting::application (
  $admin_password,
  $admin_users,
  $google_app_domain,
  $google_key,
  $google_secret,
  $jira_user,
  $jira_password,
  $launchpad_consumer_key,
  $launchpad_oauth_access_token,
  $launchpad_oauth_access_token_secret,
  $lpreports_api_url,
  $lpreports_auth_token,
  $mail_password,
  $mail_username,
  $testrail_baseurl,
  $testrail_user,
  $testrail_password,
  $app_user                  = 'qareporting',
  $app_path                  = '/usr/lib/python3/dist-packages/qareporting',
  $credential_file           = '/etc/qareporting/qareporting.conf',
  $credential_store          = '/etc/qareporting',
  $credential_store_template = 'qa_reporting/qareporting.conf.erb',
  $gzip_types                = 'text/css application/json application/javascript text/javascript',
  $logdir                    = '/var/log/qareporting',
  $modules_path              = '/usr/share/qareporting',
  $modules_path_template     = 'qa_reporting/env.erb',
  $nginx_access_log          = '/var/log/nginx/access.log',
  $nginx_error_log           = '/var/log/nginx/error.log',
  $nginx_log_format          = undef,
  $nginx_server_name         = 'localhost',
  $package                   = 'python3-qa-reporting',
  $python_path               = '/usr/bin/python3',
  $ssl_certificate           = '/etc/ssl/certs/qareporting.crt',
  $ssl_certificate_contents  = undef,
  $ssl_key                   = '/etc/ssl/private/qareporting.key',
  $ssl_key_contents          = undef,
  $static_folder             = '/var/www/static',
  $static_path               = undef,
  $uwsgi_chdir               = '/',
  $webpack_manifest_path     = 'manifest.json'
){

  include ::nginx

  ensure_packages([
    $package,
    'build-essential',
    'nodejs',
    'npm',
    'python3-dev',
    'python3-holidays',
    'python3-mongoengine',
    'mongo-tools',
  ], {
    ensure  => 'latest',
    require => [
        User[$app_user],
    ],
  })

  # create application user and group
  user { $app_user :
    ensure     => 'present',
    shell      => '/bin/false',
    home       => "/var/lib/${app_user}",
    managehome => true,
    system     => true
  }

  file { "/var/lib/${app_user}" :
    ensure  => 'directory',
    owner   => $app_user,
    group   => $app_user,
    mode    => '0755',
    require => [
        User[$app_user],
    ]
  }

  # create directory to store uwsgi logs
  file { $modules_path :
    ensure  => 'directory',
    owner   => $app_user,
    group   => $app_user,
    mode    => '0644',
    require => [
        User[$app_user],
    ]
  }

  # create directory to store uwsgi logs
  file { $logdir :
    ensure  => 'directory',
    owner   => $app_user,
    group   => $app_user,
    mode    => '0700',
    require => [
        User[$app_user],
    ]
  }

  # create directory to store the application's configuration files
  file { $credential_store :
    ensure  => 'directory',
    require => [
        User[$app_user],
        Package['python3-qa-reporting']
    ]
  }

  # create application's config file
  file { $credential_file :
    ensure  => 'file',
    owner   => $app_user,
    group   => $app_user,
    mode    => '0700',
    content => template($credential_store_template),
    require => [
        File[$credential_store],
        User[$app_user],
    ]
  }

  # create file with path to npm's build cache
  file { "${modules_path}/.env":
    ensure  => 'file',
    owner   => $app_user,
    group   => $app_user,
    content => template($modules_path_template),
    require => [
        File[$modules_path],
        User[$app_user],
    ]

  }

  # create directory to store application's lock files
  file { '/var/lock/qareporting' :
    ensure  => 'directory',
    owner   => $app_user,
    group   => $app_user,
    mode    => '0644',
    require => [
        User[$app_user],
    ]
  }

  file { "${app_path}/.cache" :
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [
        Package['python3-qa-reporting'],
    ]
  }

  file { '/usr/bin/node' :
    ensure  => 'link',
    target  => '/usr/bin/nodejs',
    require => [
        Package['nodejs'],
    ]
  }

  # Workaround on time, while we have no a way to remove this directory by
  # using debhelper.
  exec { 'remove qareporting' :
    command   => 'rm -rf qareporting/',
    cwd       => "${app_path}/",
    logoutput => true,
    require   => [
        Package['python3-qa-reporting'],
    ]
  }

  # The following three npm-related steps are needed to install nodejs packages,
  # what are used by qareporting application.
  # These steps are mandatory and couldn't be postponed.

  # install npm packages
  exec { 'install npm packages':
    command   => 'npm install',
    cwd       => $modules_path,
    logoutput => true,
    require   => [
        Package['npm'],
        Package['python3-qa-reporting'],
        User[$app_user],
        Exec['remove qareporting'],
        File['/usr/bin/node']
    ]
  }

  # clean npm cache directory
  exec { 'run npm clean':
    command   => 'npm run clean',
    cwd       => $modules_path,
    logoutput => true,
    require   => [
        Exec['install npm packages'],
    ]
  }

  # build npm modules
  exec { 'run npm build':
    command   => 'npm run build',
    cwd       => $modules_path,
    logoutput => true,
    require   => [
        Exec['run npm clean'],
    ]
  }

  # The following two steps configure application's database
  exec { 'run populate_db':
    command   => "${python_path} ${app_path}/manage.py --config production populate_db",
    logoutput => true,
    require   => [
        Package['python3-qa-reporting'],
        File[$credential_file],
        Exec['run npm build']
    ]
  }

  exec { 'run clear_cache':
    command   => "${python_path} ${app_path}/manage.py --config production clear_cache",
    logoutput => true,
    require   => [
        Package['python3-qa-reporting'],
        File[$credential_file],
        Exec['run npm build']
    ]
  }

  # The following two steps configure SSL-certificate and SSL key
  file { $ssl_certificate :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_certificate_contents,
  }

  file { $ssl_key :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_key_contents,
  }

  # configure uwsgi modules to run application
  uwsgi::application { 'qareporting' :
    plugins   => 'python3',
    module    => 'wsgi',
    callable  => 'app',
    master    => true,
    lazy_apps => true,
    workers   => $::processorcount,
    socket    => '127.0.0.1:6776',
    vacuum    => true,
    uid       => $app_user,
    gid       => $app_user,
    chdir     => $uwsgi_chdir,
    require   => [
      File[$logdir],
      Package['python3-qa-reporting'],
      User[$app_user],
      Exec['run npm build']
    ],
    subscribe => [
      Package['python3-qa-reporting'],
    ]
  }

  # The following two steps configure nginx-related data
  ::nginx::resource::vhost { 'qareporting-http' :
    ensure              => 'present',
    server_name         => [$nginx_server_name],
    listen_port         => 80,
    www_root            => '/var/www',
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      return => "301 https://${nginx_server_name}\$request_uri",
    },
  }

  ::nginx::resource::vhost { 'qareporting' :
    ensure               => 'present',
    listen_port          => 443,
    ssl_port             => 443,
    server_name          => [$nginx_server_name],
    ssl                  => true,
    ssl_cert             => $ssl_certificate,
    ssl_key              => $ssl_key,
    ssl_cache            => 'shared:SSL:10m',
    ssl_session_timeout  => '10m',
    ssl_stapling         => true,
    ssl_stapling_verify  => true,
    access_log           => $nginx_access_log,
    error_log            => $nginx_error_log,
    format_log           => $nginx_log_format,
    uwsgi                => '127.0.0.1:6776',
    client_max_body_size => '75M',
    gzip_types           => $gzip_types,
    location_cfg_append  => {
      uwsgi_connect_timeout  => '3m',
      uwsgi_read_timeout     => '3m',
      uwsgi_send_timeout     => '3m',
      uwsgi_intercept_errors => 'on',
    },
    require              => [
      File[$ssl_certificate],
      File[$ssl_key],
      Package['python3-qa-reporting'],
    ],
  }

  # configuring of a set of cronjob to get data from different sources (Jira, Google, Testrail and so on)
  cron { 'jira job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-jira.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production sync_jira 2>&1 | logger -t qareporting-jira",
    user    => $app_user,
    minute  => '*/15',
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'launchpad job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-lp.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production sync_launchpad -tpb 2>&1 | logger -t qareporting-launchpad",
    user    => $app_user,
    minute  => '*/15',
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'testrail fast job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-testrail-fast.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production sync_testrail --fast 2>&1 | logger -t qareporting-testrail-fast",
    user    => $app_user,
    minute  => '*/20',
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'testrail full job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-testrail.lock /usr/bin/timeout -k10 9000 ${python_path} ${app_path}/manage.py --config production sync_testrail 2>&1 | logger -t qareporting-testrail",
    user    => $app_user,
    hour    => 0,
    minute  => 15,
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'mail job 18:12':
    command => "/usr/bin/flock -n -x /var/lock/qareport-mail.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production send_mail -m 22 2>&1 | logger -t qareporting-mail",
    user    => $app_user,
    hour    => 18,
    minute  => 12,
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'send notifications job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-mail.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production send_notifications 2>&1 | logger -t qareporting-mail-send-notifications",
    user    => $app_user,
    weekday => 'sat',
    hour    => 9,
    minute  => 0,
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'check unfinished job':
    command => "/usr/bin/flock -n -x /var/lock/check-unfinished.lock /usr/bin/timeout -k10 60 ${python_path} ${app_path}/manage.py --config production check_unfinished 2>&1 | logger -t check_unfinished",
    user    => $app_user,
    hour    => 5,
    minute  => 0,
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

  cron { 'send incomplete job':
    command => "/usr/bin/flock -n -x /var/lock/qareport-mail.lock /usr/bin/timeout -k10 1800 ${python_path} ${app_path}/manage.py --config production send_incomplete -m 10.0 2>&1 | logger -t qareporting-mail-send-incomplete",
    user    => $app_user,
    weekday => 'mon',
    hour    => 10,
    minute  => 0,
    require => [
      Package['python3-qa-reporting'],
      User[$app_user],
      File[$credential_file],
      Exec['run npm build'],
    ],
  }

}
