# Class: fuel_project::plugins
#
class fuel_project::plugins (
  $service_fqdn = "plugins.${::fqdn}",
  $plugins_dir = '/var/www/plugins',
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $sync_hosts_allow = [],
  $nginx_access_log = '/var/log/nginx/access.log',
  $nginx_error_log = '/var/log/nginx/error.log',
  $nginx_log_format = 'proxy',
) {
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

  if (!defined(File['/var/www'])) {
    file { '/var/www' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      before => File[$plugins_dir],
    }
  }

  file { $plugins_dir :
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

  ::rsync::server::module{ 'plugins':
    comment         => 'Fuel plugins sync',
    uid             => 'www-data',
    gid             => 'www-data',
    hosts_allow     => $sync_hosts_allow,
    hosts_deny      => ['*'],
    incoming_chmod  => '0755',
    outgoing_chmod  => '0644',
    list            => 'yes',
    lock_file       => '/var/run/rsync_plugins_sync.lock',
    max_connections => 100,
    path            => $plugins_dir,
    read_only       => 'no',
    write_only      => 'no',
    require         => File[$plugins_dir],
  }
}
