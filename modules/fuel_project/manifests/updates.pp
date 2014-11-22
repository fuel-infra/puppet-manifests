# Class: fuel_project::update
#
class fuel_project::updates (
  $service_fqdn = "updates.${::fqdn}",
  $updates_dir = '/var/www/updates',
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $sync_hosts_allow = [],
) {
  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'updates' :
    ensure      => 'present',
    autoindex   => 'on',
    www_root    => $updates_dir,
    server_name => [$service_fqdn, "updates.${::fqdn}"]
  }

  if (!defined(File['/var/www'])) {
    file { '/var/www' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      before => File[$updates_dir],
    }
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
