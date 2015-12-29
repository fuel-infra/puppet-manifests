# Class: fuel_project::apps::seed
#
# This class deploys Nginx powered http based storage with ability to put
# images from a different locations.
#
# Parameters:
#   [*apply_firewall_rules*] - add firewall rules for declared for this class
#   [*client_max_body_size*] - maximum size of single file uploaded by PUT
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_log_format*] - log format
#   [*seed_cleanup_dirs*] - directories to clean by downloads_cleaner
#   [*seed_dir*] - seed storage directory
#   [*seed_port*] - daemon listening port
#   [*service_fqdn*] - FQDN for the service
#   [*vhost_acl_allow*] - hosts allowed to PUT data
#
class fuel_project::apps::seed (
  $apply_firewall_rules = false,
  $client_max_body_size = '5G',
  $nginx_access_log     = '/var/log/nginx/access.log',
  $nginx_error_log      = '/var/log/nginx/error.log',
  $nginx_log_format     = 'proxy',
  $seed_cleanup_dirs    = undef,
  $seed_dir             = '/var/www/seed',
  $seed_port            = 17333,
  $service_fqdn         = "seed.${::fqdn}",
  # FIXME: Make one list for hosts on L3 and L7
  $vhost_acl_allow = [],
) {
  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'seed' :
    ensure           => 'present',
    access_log       => $nginx_access_log,
    error_log        => $nginx_error_log,
    format_log       => $nginx_log_format,
    www_root         => $seed_dir,
    server_name      => [$service_fqdn, $::fqdn],
    vhost_cfg_append => {
      autoindex        => 'off',
      disable_symlinks => 'if_not_owner',
    },
  }

  ::nginx::resource::vhost { 'seed-upload' :
    ensure              => 'present',
    autoindex           => 'off',
    www_root            => $seed_dir,
    listen_port         => $seed_port,
    server_name         => [$::fqdn],
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      dav_methods          => 'PUT',
      client_max_body_size => $client_max_body_size,
      allow                => $vhost_acl_allow,
      deny                 => 'all',
      disable_symlinks     => 'if_not_owner',
    }
  }

  ensure_resource('file', '/var/www', {
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '0755',
    before => File[$seed_dir],
  })

  file { $seed_dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Class['nginx'],
  }

  class {'::devopslib::downloads_cleaner' :
    cleanup_dirs => $seed_cleanup_dirs,
  }
}
