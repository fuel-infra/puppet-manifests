# Class: fuel_project::redirection
#
# This class deploys simple nginx based redirection virtual host.
#
# Parameters:
#   [*server_name*] - service hostname
#   [*nginx_access_log*] - access log
#   [*nginx_error_log*] - error log
#   [*redirection_link*] - error log
#
class fuel_project::redirection (
  $server_name      = undef,
  $nginx_access_log = '/var/log/nginx/access.log',
  $nginx_error_log  = '/var/log/nginx/error.log',
  $redirect_link    = undef,
){

  if ( ! defined(Class['::nginx']) ) {
    class { '::nginx' : }
  }

  ::nginx::resource::vhost { $server_name :
    ensure              => 'present',
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    listen_port         => 80,
    location_cfg_append => {
      return => "301 ${redirect_link}\$request_uri",
    },
    server_name         => [$server_name],
    www_root            => '/var/www'
  }

}
