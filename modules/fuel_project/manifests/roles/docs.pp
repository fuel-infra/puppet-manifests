# Class: fuel_proect::roles::docs
#
# This class deploys docs role.
#
# Parameters:
#   [*app_secret_key*] - application's secret key for uwsgi application
#   [*client_id*] - Google's crendetials client id for the application
#   [*client_secret*] - Google's crendetials client secret for the application
#   [*conf_mode*] - mode to run application (Prod or Dev)
#   [*debug*] - enable or disable debug mode for application
#   [*community_hostname*] - community service hostname
#   [*community_ssl_cert_content*] - community SSL certificate contents
#   [*community_ssl_cert_filename*] - community SSL certificate path
#   [*community_ssl_key_content*] - community SSL key contents
#   [*community_ssl_key_filename*] - community SSL key path
#   [*config_file*] - application's config file
#   [*config_file_path*] - directory to store application's config file
#   [*config_file_path_template*] - path to template for applicaton config file
#   [*docs_user*] - user to install docs
#   [*fuel_version*] - fuel version
#   [*hostname*] - service hostname
#   [*logdir*] - directory to collect application's logs
#   [*nginx_access_log*] - access log
#   [*nginx_error_log*] - error log
#   [*nginx_log_format*] - log format
#   [*specs_hostname*] - specs service hostname
#   [*sqlalchemy_database_uri*] - database uri
#   [*sqlalchemy_track_modification*] - track modifications of objects and emit signals
#   [*ssh_auth_key*] - SSH authorized key
#   [*ssl_cert_content*] - SSL certificate contents
#   [*ssl_cert_filename*] - SSL certificate file path
#   [*ssl_key_content*] - SSL key contents
#   [*ssl_key_filename*] - SSL key file path
#   [*trusted_proxies*] - list of networks to allow connections to a private part
#   [*uwsgi_chdir*] - path for uwsgi to search initial module for application
#   [*www_root*] - www root path
#
class fuel_project::roles::docs (
  $app_secret_key,
  $client_id,
  $client_secret,
  $conf_mode,
  $debug,
  $oauth2_provider_token_expires_in,
  $run_host,
  $sqlalchemy_database_uri,
  $sqlalchemy_track_modification,
  $trusted_proxies,
  $community_hostname          = 'docs.fuel-infra.org',
  $community_ssl_cert_content  = '',
  $community_ssl_cert_filename = '/etc/ssl/community-docs.crt',
  $community_ssl_key_content   = '',
  $community_ssl_key_filename  = '/etc/ssl/community-docs.key',
  $config_file                 = '/etc/flask-auth/config.yml',
  $config_file_path            = '/etc/flask-auth/',
  $config_file_path_template   = 'fuel_project/roles/docs/config.yml.erb',
  $docs_user                   = 'docs',
  $fuel_version                = '6.0',
  $hostname                    = 'docs.mirantis.com',
  $logdir                      = '/var/log/flask_auth',
  $nginx_access_log            = '/var/log/nginx/access.log',
  $nginx_error_log             = '/var/log/nginx/error.log',
  $nginx_log_format            = undef,
  $specs_hostname              = 'specs.fuel-infra.org',
  $ssh_auth_key                = undef,
  $ssl_cert_content            = '',
  $ssl_cert_filename           = '/etc/ssl/docs.crt',
  $ssl_key_content             = '',
  $ssl_key_filename            = '/etc/ssl/docs.key',
  $uwsgi_chdir                 = '/usr/lib/python2.7/dist-packages/flask_auth/',
  $www_root                    = '/var/www',
) {
  if ( ! defined(Class['::fuel_project::nginx']) ) {
    class { '::fuel_project::nginx' : }
  }

  user { $docs_user :
    ensure     => 'present',
    shell      => '/bin/bash',
    managehome => true,
  }

  ensure_packages([
    'python-ipaddress',
    'python-flask-auth',
    ],
    {'ensure' => 'latest'}
  )

  if ($ssl_cert_content and $ssl_key_content) {
    file { $ssl_cert_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $ssl_cert_content,
    }
    file { $ssl_key_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $ssl_key_content,
    }
    Nginx::Resource::Vhost <| title == $hostname |> {
      ssl         => true,
      ssl_cert    => $ssl_cert_filename,
      ssl_key     => $ssl_key_filename,
      listen_port => 443,
      ssl_port    => 443,
    }
    ::nginx::resource::vhost { "${hostname}-redirect" :
      ensure              => 'present',
      server_name         => [$hostname],
      listen_port         => 80,
      www_root            => $www_root,
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${hostname}\$request_uri",
      },
    }
    $ssl = true
  } else {
    $ssl = false
  }

  if ($community_ssl_cert_content and $community_ssl_key_content) {
    file { $community_ssl_cert_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $community_ssl_cert_content,
    }
    file { $community_ssl_key_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $community_ssl_key_content,
    }

    Nginx::Resource::Vhost <| title == $community_hostname |> {
      ssl         => true,
      ssl_cert    => $community_ssl_cert_filename,
      ssl_key     => $community_ssl_key_filename,
      listen_port => 443,
      ssl_port    => 443,
    }
    ::nginx::resource::vhost { "${community_hostname}-redirect" :
      ensure              => 'present',
      server_name         => [$community_hostname],
      listen_port         => 80,
      www_root            => $www_root,
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${community_hostname}\$request_uri",
      },
    }
    $community_ssl = true
  } else {
    $community_ssl = false
  }

  if ($ssh_auth_key) {
    ssh_authorized_key { 'fuel_docs@jenkins' :
      user    => $docs_user,
      type    => 'ssh-rsa',
      key     => $ssh_auth_key,
      require => User[$docs_user],
    }
  }

  ::nginx::resource::vhost { $community_hostname :
    ensure              => 'present',
    server_name         => [$community_hostname],
    listen_port         => 80,
    www_root            => $www_root,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    uwsgi               => '127.0.0.1:6776',
    location_cfg_append => {
      uwsgi_connect_timeout  => '3m',
      uwsgi_read_timeout     => '3m',
      uwsgi_send_timeout     => '3m',
      uwsgi_intercept_errors => 'on',
      'rewrite'              => {
        '^/$'                => '/fuel-dev',
        '^/express/?$'       => '/openstack/express/latest',
        '^/(express/.+)'     => '/openstack/$1',
        '^/fuel/?$'          => "/openstack/fuel/fuel-${fuel_version}",
        '^/(fuel/.+)'        => '/openstack/$1',
        '^/openstack/fuel/$' => "/openstack/fuel/fuel-${fuel_version}",
      },
    },
    vhost_cfg_append    => {
      'error_page 403'         => '/fuel-infra/403.html',
      'error_page 404'         => '/fuel-infra/404.html',
      'error_page 500 502 504' => '/fuel-infra/5xx.html',
    }
  }

  # error pages for community
  ::nginx::resource::location { "${community_hostname}-error-pages" :
    ensure   => 'present',
    vhost    => $community_hostname,
    location => '~ ^\/fuel-infra\/(403|404|5xx)\.html$',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/error_pages',
    require  => Package['error-pages'],
  }

  # Disable fuel-master docs on community site
  ::nginx::resource::location { "${community_hostname}/openstack/fuel/fuel-master" :
    vhost               => $community_hostname,
    location            => '~ \/openstack\/fuel\/fuel-master\/.*',
    www_root            => $www_root,
    ssl                 => $community_ssl,
    ssl_only            => $community_ssl,
    location_cfg_append => {
      return => 404,
    },
  }

  # Disable mirantis fuel docs on community site
  ::nginx::resource::location { "${community_hostname}/openstack/" :
    vhost               => $community_hostname,
    location            => '~ \/openstack\/.*',
    www_root            => $www_root,
    ssl                 => $community_ssl,
    ssl_only            => $community_ssl,
    location_cfg_append => {
      return => 404,
    },
  }

  ::nginx::resource::location { "${community_hostname}/fuel-dev" :
    vhost               => $community_hostname,
    location            => '/fuel-dev',
    location_alias      => "${www_root}/fuel-dev-docs/fuel-dev-master",
    ssl                 => $community_ssl,
    ssl_only            => $community_ssl,
    location_cfg_append => {
      'rewrite' => {
        '^/fuel-dev/(.*)$' => 'http://docs.openstack.org/developer/fuel-docs',
      }
    },
  }

  # Bug: https://bugs.launchpad.net/fuel/+bug/1473440
  ::nginx::resource::location { "${community_hostname}/fuel-qa" :
    vhost          => $community_hostname,
    location       => '/fuel-qa',
    location_alias => "${www_root}/fuel-qa/fuel-master",
    ssl            => $community_ssl,
    ssl_only       => $community_ssl,
  }

  ::nginx::resource::vhost { $hostname :
    ensure              => 'present',
    server_name         => [$hostname],
    listen_port         => 80,
    www_root            => $www_root,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    uwsgi               => '127.0.0.1:6776',
    location_cfg_append => {
      'rewrite' => {
        '^/$'                                           => "/mcp",
        '^/fuel-dev/?(.*)$'                             => "http://${community_hostname}/fuel-dev/\$1",
        '^/express/?$'                                  => '/openstack/express/latest',
        '^/(express/.+)'                                => '/openstack/$1',
        '^/fuel/?$'                                     => "/openstack/fuel/fuel-${fuel_version}",
        '^/(fuel/.+)'                                   => '/openstack/$1',
        '^/openstack/fuel/$'                            => "/openstack/fuel/fuel-${fuel_version}",
        '^/openstack/fuel/fuel-9.0/operations.html$'    => '/openstack/fuel/fuel-8.0/operations.html permanent',
        '^/openstack/fuel/fuel-master/operations?(.*)$' => '/openstack/fuel/fuel-master/index.html permanent',
      },
    },
    require             => [
      File[$ssl_cert_filename],
      File[$ssl_key_filename],
      Package['python-flask-auth'],
    ],
    vhost_cfg_append    => {
      'error_page 403'         => '/mirantis/403.html',
      'error_page 404'         => '/mirantis/404.html',
      'error_page 500 502 504' => '/mirantis/5xx.html',
    }
  }

  # error pages for primary docs
  ::nginx::resource::location { "${hostname}-error-pages" :
    ensure   => 'present',
    vhost    => $hostname,
    location => '~ ^\/mirantis\/(403|404|5xx)\.html$',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/error_pages',
    require  => [
      Package['error-pages'],
    ],
  }

  if (! defined(File[$www_root])) {
    file { $www_root :
      ensure  => 'directory',
      mode    => '0755',
      owner   => $docs_user,
      group   => $docs_user,
      require => User[$docs_user],
    }
  } else {
    File <| title == $www_root |> {
      owner   => $docs_user,
      group   => $docs_user,
      require => User[$docs_user],
    }
  }

  ::nginx::resource::vhost { $specs_hostname :
    server_name         => [$specs_hostname],
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    www_root            => $www_root,
    location_cfg_append => {
      'rewrite' => {
        '^/(.*)$' => 'https://specs.openstack.org/openstack/fuel-specs/$1',
      },
    },
  }

  # -- configure uwsgi application --

  # create directory to store uwsgi logs
  file { $logdir :
    ensure  => 'directory',
    owner   => $docs_user,
    group   => $docs_user,
    mode    => '0700',
    require => [
        User[$docs_user],
    ]
  }

  # create directory to store the application's configuration files
  file { $config_file_path :
    ensure  => 'directory',
    require => [
        User[$docs_user],
        Package['python-flask-auth']
    ]
  }

  # create application's config file
  file { $config_file :
    ensure  => 'file',
    owner   => $docs_user,
    group   => $docs_user,
    mode    => '0700',
    content => template($config_file_path_template),
    require => [
        Package['python-flask-auth'],
        File[$config_file_path],
        User[$docs_user],
    ]
  }

  # create directory to store application's lock files
  file { '/var/lock/flask-auth' :
    ensure  => 'directory',
    owner   => $docs_user,
    group   => $docs_user,
    mode    => '0644',
    require => [
        User[$docs_user],
    ]
  }

  # create directory to store database for the application
  file { '/var/lib/flask-auth' :
    ensure  => 'directory',
    owner   => $docs_user,
    group   => $docs_user,
    mode    => '0644',
    require => [
        User[$docs_user],
    ]
  }


  uwsgi::application { 'flask-auth' :
    plugins   => 'python',
    module    => 'run',
    callable  => 'app',
    master    => true,
    lazy_apps => true,
    workers   => '2',
    socket    => '127.0.0.1:6776',
    vacuum    => true,
    uid       => $docs_user,
    gid       => $docs_user,
    chdir     => $uwsgi_chdir,
    require   => [
      File[$logdir],
      Package['python-flask-auth'],
      User[$docs_user],
    ],
    subscribe => [
      Package['python-flask-auth'],
    ]
  }

}
