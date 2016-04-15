# Class: landing_page::docs
#
# This class deploys a simple web page to serve a collection of links to main
# landing page resources.
#
# Parameters:
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_log_format*] - log format
#   [*nginx_server_name*] - service host name
#   [*nginx_www_root*] - www_root path for service
#   [*package*] - package providing landing page documents
#
class landing_page::docs (
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = 'proxy',
  $nginx_server_name      = $::fqdn,
  $nginx_www_root         = '/var/www/docs_landing',
  $package                = 'landing-page-docs',
) {
  include ::nginx

  package { $package :
    ensure => 'latest',
  }

  ::nginx::resource::vhost { 'docs_landing' :
    server_name => [$nginx_server_name],
    listen_port => 80,
    www_root    => $nginx_www_root,
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
  }
}
