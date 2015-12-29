# Class: fuel_project::apps::update
#
# This class deploys Nginx powered share with ability to upload files via rsync
# protocol.
#
# Paramters:
#   [*apply_firewall_rules*] - unused variable
#   [*firewall_allow_sources*] - unused variable
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_log_format*] - log format
#   [*service_fqdn*] - FQDN for this service
#   [*sync_hosts_allow*] - hosts allowed to use RW rsync share
#   [*updates_dir*] - path where files are store
#
class fuel_project::apps::updates (
  $apply_firewall_rules   = false,
  $firewall_allow_sources = {},
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = 'proxy',
  $service_fqdn           = "updates.${::fqdn}",
  $sync_hosts_allow       = [],
  $updates_dir            = '/var/www/updates',
) {
  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'updates' :
    ensure           => 'present',
    autoindex        => 'on',
    access_log       => $nginx_access_log,
    error_log        => $nginx_error_log,
    format_log       => $nginx_log_format,
    www_root         => $updates_dir,
    server_name      => [$service_fqdn, "updates.${::fqdn}"],
    vhost_cfg_append => {
      disable_symlinks => 'if_not_owner',
    },
  }

  file { $updates_dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Class['::nginx'],
  }

  if (!defined(Class['::rsync::server'])) {
    class { '::rsync::server' :
      gid        => 'root',
      uid        => 'root',
      use_chroot => 'yes',
      use_xinetd => false,
    }
  }

  ::rsync::server::module{ 'updates':
    comment         => 'Fuel updates sync',
    uid             => 'www-data',
    gid             => 'www-data',
    hosts_allow     => $sync_hosts_allow,
    hosts_deny      => ['*'],
    incoming_chmod  => '0755',
    outgoing_chmod  => '0644',
    list            => 'yes',
    lock_file       => '/var/run/rsync_updates_sync.lock',
    max_connections => 100,
    path            => $updates_dir,
    read_only       => 'no',
    write_only      => 'no',
    require         => File[$updates_dir],
  }
}
