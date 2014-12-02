# Class: fuel_project::mirror
#
class fuel_project::mirror (
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $dir = '/var/www/mirror',
  $firewall_allow_sources = {},
  $port = 80,
  $service_fqdn = "mirror.${::fqdn}",
  $service_aliases = [],
  $sync_hosts_allow = [],
) {
  class { 'rsync':
    package_ensure => 'present',
  }

  if (!defined(File['/var/www'])) {
    file { '/var/www' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      before => File[$dir]
    }
  }

  file { $dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Class['nginx'],
  }

  if (!defined(Class['::rsync::server'])) {
    class { '::rsync::server' :
      gid        => 'root',
      uid        => 'root',
      use_chroot => 'yes',
      use_xinetd => false,
    }
  }

  ::rsync::server::module{ 'mirror':
    comment         => 'Fuel mirror rsync share',
    uid             => 'nobody',
    gid             => 'nogroup',
    list            => 'yes',
    lock_file       => '/var/run/rsync_mirror.lock',
    max_connections => 100,
    path            => $dir,
    read_only       => 'yes',
    write_only      => 'no',
    require         => File[$dir],
  }

  ::rsync::server::module{ 'mirror-sync':
    comment         => 'Fuel mirror sync',
    uid             => 'www-data',
    gid             => 'www-data',
    hosts_allow     => $sync_hosts_allow,
    hosts_deny      => ['*'],
    incoming_chmod  => '0755',
    outgoing_chmod  => '0644',
    list            => 'yes',
    lock_file       => '/var/run/rsync_mirror_sync.lock',
    max_connections => 100,
    path            => $dir,
    read_only       => 'no',
    write_only      => 'no',
    require         => File[$dir],
  }

  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'mirror' :
    ensure              => 'present',
    www_root            => '/var/www/mirror',
    server_name         => [
      $service_fqdn,
      "mirror.${::fqdn}",
      join($service_aliases, ' ')
    ],
    location_cfg_append => {
        autoindex => 'on',
    },
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => [$port, 873],
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
