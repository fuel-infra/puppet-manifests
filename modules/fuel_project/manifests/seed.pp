# Class: fuel_project::seed
#
class fuel_project::seed (
  $apply_firewall_rules = false,
  $client_max_body_size = '5G',
  $external_host = false,
  $firewall_allow_sources = {},
  $nginx_access_log = '/var/log/nginx/access.log',
  $nginx_error_log = '/var/log/nginx/error.log',
  $nginx_log_format = 'proxy',
  $seed_cleanup_dirs = undef,
  $seed_dir = '/var/www/seed',
  $seed_port = 17333,
  $service_fqdn = "seed.${::fqdn}",
  $tracker_apply_firewall_rules = false,
  $tracker_firewall_allow_sources = {},
  # FIXME: Make one list for hosts on L3 and L7
  $vhost_acl_allow = [],
) {
  class { '::opentracker' :
    apply_firewall_rules   => $tracker_apply_firewall_rules,
    firewall_allow_sources => $tracker_firewall_allow_sources,
  }

  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'seed' :
    ensure      => 'present',
    autoindex   => 'off',
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
    www_root    => $seed_dir,
    server_name => [$service_fqdn, $::fqdn]
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
    }
  }

  if (!defined(File['/var/www'])) {
    ensure_resource('file', '/var/www', {
      ensure => 'directory',
      owner => 'root',
      group => 'root',
      mode => '0755',
      before => File[$seed_dir],
    })
  }

  file { $seed_dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Class['nginx'],
  }

  class {'::devopslib::downloads_cleaner' :
    cleanup_dirs => $seed_cleanup_dirs,
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => $seed_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
