# Class: etherpad_lite::webapp
#
# This class deploys fully functional etherpad instance. Required parameters
# are SSL certificate and key as usually. Hiera example role 'etherpad'
# provides commented config hashes which are also required.
#
# Parameters:
#   [*ssl_certificate_contents*] - ssl certificate content for client connections
#   [*ssl_key_contents*] - ssl key content for client connections
#   [*config_path*] - etherpad config location
#   [*config_template*] - config template for Puppet
#   [*nginx_access_log*] - access log file
#   [*nginx_error_log*] - error log file
#   [*nginx_log_format*] - log format
#   [*nginx_proxy_pass*] - etherpad backend port
#   [*nginx_server_name*] - vhost hostname
#   [*packages*] - required packages
#   [*ssl_certificate*] - ssl certificate path for client connections
#   [*ssl_key*] - ssl key path for client connections
#
# webapp::config:
#   [*maxAge*] - How long may clients use served javascript code (in seconds)? Without versioning this may cause problems during deployment. Set to 0 to disable caching.
#   [*abiword*] - This is the path to the Abiword executable. Setting it to null, disables abiword.  Abiword is needed to advanced import/export features of pads.
#   [*tidyHtml*] - This is the path to the Tidy executable. Setting it to null, disables Tidy. Tidy is used to improve the quality of exported pads*/
#   [*allowUnknownFileEnds*] - Allow import of file types other than the supported types: txt, doc, docx, rtf, odt, html & htm.
#   [*requireAuthentication*] - This setting is used if you require authentication of all users.
#   [*requireAuthorization*] - Require authorization by a module, or a user with is_admin set, see below.
#   [*trustProxy*] - When you use NginX or another proxy/ load-balancer set this to true.
#   [*disableIPlogging*] - Privacy: disable IP logging.
#   [*socketTransportProtocols*] - Restrict socket.io transport methods.
#   [*loadTest*] - Allow Load Testing tools to hit the Etherpad Instance.  Warning this will disable security on the instance.
#   [*loglevel*] - The log level we are using, can be: DEBUG, INFO, WARN, ERROR.

class etherpad_lite::webapp (
  $ssl_certificate_contents,
  $ssl_key_contents,
  $config_path              = '/etc/etherpad-lite/settings.json',
  $config_template          = 'etherpad_lite/settings.json.erb',
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = undef,
  $nginx_proxy_pass         = 'http://127.0.0.1:9001',
  $nginx_server_name        = $::fqdn,
  $packages                 = ['etherpad-lite'],
  $ssl_certificate          = '/etc/ssl/certs/etherpad.crt',
  $ssl_key                  = '/etc/ssl/private/etherpad.key',
) {
  $config = hiera_hash('etherpad_lite::webapp::config', {})
  $files = hiera_hash('etherpad_lite::webapp::files', {})
  ensure_packages($packages)

  file { $config_path :
    ensure  => 'present',
    mode    => '0400',
    owner   => 'etherpad',
    group   => 'etherpad',
    content => template($config_template),
    notify  => Service['etherpad-lite'],
    require => Package[$packages],
  }

  file { $ssl_certificate :
    ensure  => 'present',
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
    content => $ssl_certificate_contents,
  }

  file { $ssl_key :
    ensure  => 'present',
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
    content => $ssl_key_contents,
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'etherpad-http' :
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

  ::nginx::resource::vhost { 'etherpad' :
    ensure              => 'present',
    listen_port         => 443,
    ssl_port            => 443,
    server_name         => [$nginx_server_name],
    ssl                 => true,
    ssl_cert            => $ssl_certificate,
    ssl_key             => $ssl_key,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    proxy               => $nginx_proxy_pass,
    proxy_set_header    => [
      'X-Forwarded-For $remote_addr',
      'Host $host',
    ],
    location_cfg_append => {
      proxy_intercept_errors   => 'on',
      'error_page 403'         => '/fuel-infra/403.html',
      'error_page 404'         => '/fuel-infra/404.html',
      'error_page 500 502 504' => '/fuel-infra/5xx.html',
    },
    require             => [
      File[$ssl_certificate],
      File[$ssl_key],
    ],
  }

  ::nginx::resource::location { 'static' :
    ensure                => 'present',
    vhost                 => 'etherpad',
    ssl                   => true,
    ssl_only              => true,
    location              => '/static/',
    proxy                 => $nginx_proxy_pass,
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
      proxy_intercept_errors   => 'on',
      'error_page 403'         => '/fuel-infra/403.html',
      'error_page 404'         => '/fuel-infra/404.html',
      'error_page 500 502 504' => '/fuel-infra/5xx.html',
    },
  }

  service { 'etherpad-lite' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => [
      Package[$packages],
      File[$config_path],
    ]
  }
}
