# Class: fuel_project::apps::plugins
#
class fuel_project::apps::plugins (
  $apply_firewall_rules   = false,
  $firewall_allow_sources = {},
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = 'proxy',
  $plugins_dir            = '/var/www/plugins',
  $service_fqdn           = "plugins.${::fqdn}",
  $syncer_username        = 'plugin-syncer',
  $syncer_ssh_keys        = {},
) {
  include rssh
  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'plugins' :
    ensure      => 'present',
    autoindex   => 'on',
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
    www_root    => $plugins_dir,
    server_name => [$service_fqdn, "plugins.${::fqdn}"]
  }

  file { $plugins_dir :
    ensure  => 'directory',
    owner   => $syncer_username,
    group   => $syncer_username,
    require => Class['::nginx'],
  }

  $syncer_homedir = "/var/lib/${syncer_username}"

  user { $syncer_username :
    ensure     => 'present',
    home       => $syncer_homedir,
    shell      => '/usr/bin/rssh',
    managehome => true,
    system     => true,
  }

  file { $syncer_homedir :
    ensure  => 'directory',
    owner   => $syncer_username,
    group   => $syncer_username,
    require => User[$syncer_username],
  }

  create_resources('ssh_authorized_key', $syncer_ssh_keys, {
    user    => $syncer_username,
    require => [
      User[$syncer_username],
      File[$plugins_dir],
      File[$syncer_homedir],
    ]})
}
