# Class: fuel_project::mirror
#
class fuel_project::mirror (
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $dir = '/var/www/mirror',
  $firewall_allow_sources = {},
  $port = 80,
  $service_fqdn = "mirror.${::fqdn}",
  $sync_hosts_allow = [],
) {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      apply_firewall_rules => $apply_firewall_rules,
      create_www_dir       => true,
    }
  }
  include ::nginx::service
  class { 'rsync':
    package_ensure => 'present',
  }

  file { $dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Class['nginx'],
  }

  class { 'rsync::server' :
    gid        => 'root',
    uid        => 'root',
    use_chroot => 'yes',
    use_xinetd => false,
  }

  rsync::server::module{ 'mirror':
    comment         => 'Fuel rsync mirror',
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

  rsync::server::module{ 'mirror-sync':
    comment         => 'Fuel sync',
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

  file { '/etc/nginx/sites-available/mirror.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/mirror/nginx.conf.erb'),
    require => Class['nginx'],
  }~>
  Service['nginx']

  file { '/etc/nginx/sites-enabled/mirror.conf' :
    ensure  => 'link',
    target  => '/etc/nginx/sites-available/mirror.conf',
    require => File['/etc/nginx/sites-available/mirror.conf'],
  }~>
  Service['nginx']

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => 873,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
