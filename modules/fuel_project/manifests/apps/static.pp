# Class: fuel_project::apps::static
#
# This class deploys Nginx powered simple web share with specific directory.
#
# Parameters:
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_log_format*] - log format
#   [*packages*] - packages to install
#   [*service_fqdn*] - FQDN of web service
#   [*ssl_certificate*] - SSL certificate path
#   [*ssl_certificate_content*] - SSL certificate content
#   [*ssl_key*] - SSL key path
#   [*ssl_key_content*] - SSL key content
#   [*static_dir*] - directory to share
#
class fuel_project::apps::static (
  $nginx_access_log        = '/var/log/nginx/access.log',
  $nginx_error_log         = '/var/log/nginx/error.log',
  $nginx_log_format        = undef,
  $packages                = ['javascript-bundle'],
  $service_fqdn            = $::fqdn,
  $ssl_certificate         = '/etc/ssl/certs/static.crt',
  $ssl_certificate_content = '',
  $ssl_key                 = '/etc/ssl/private/static.key',
  $ssl_key_content         = '',
  $static_dir              = '/usr/share/javascript',
) {
  ensure_packages($packages)

  if($ssl_certificate and $ssl_certificate_content) {
    file { $ssl_certificate :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_certificate_content,
    }
  }

  if($ssl_key and $ssl_key_content) {
    file { $ssl_key :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_content,
    }
  }

  ::nginx::resource::vhost { 'static' :
    ensure           => 'present',
    autoindex        => 'off',
    access_log       => $nginx_access_log,
    error_log        => $nginx_error_log,
    format_log       => $nginx_log_format,
    ssl              => true,
    listen_port      => 80,
    ssl_port         => 443,
    ssl_cert         => $ssl_certificate,
    ssl_key          => $ssl_key,
    www_root         => $static_dir,
    server_name      => [$service_fqdn, "static.${::fqdn}"],
    gzip_types       => 'text/css application/x-javascript',
    vhost_cfg_append => {
      'add_header' => "'Access-Control-Allow-Origin' '*'",
    },
    require          => [
      Package[$packages],
      File[$ssl_certificate],
      File[$ssl_key],
    ],
  }
}
