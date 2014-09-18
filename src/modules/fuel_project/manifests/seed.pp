# Class: fuel_project::seed
#
class fuel_project::seed (
  $apply_firewall_rules = false,
  $client_max_body_size = '5G',
  $external_host = false,
  $firewall_allow_sources = {},
  $mirror = false,
  $mirror_apply_firewall_rules = false,
  $mirror_firewall_allow_sources = {},
  $mirror_sync_hosts_allow = [],
  $seed_dir = '/var/www',
  $seed_port = 17333,
  $service_fqdn = $::fqdn,
  $tracker_apply_firewall_rules = false,
  $tracker_firewall_allow_sources = {},
) {
  include nginx
  include nginx::service
  include nginx::share
  class { '::fuel_project::common' :
    external_host => $external_host,
  }
  class { '::opentracker' :
    apply_firewall_rules   => $tracker_apply_firewall_rules,
    firewall_allow_sources => $tracker_firewall_allow_sources,
  }
  file { '/etc/nginx/sites-available/seed.conf' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/seed/nginx.conf.erb'),
    require => Class['nginx'],
  }->
  file { '/etc/nginx/sites-enabled/seed.conf' :
    ensure => 'link',
    target => '/etc/nginx/sites-available/seed.conf',
  }~>
  Service['nginx']

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => $seed_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }

  if ($mirror) {
    class { 'rsync':
      package_ensure => 'present',
    }

    file { '/var/www/mirrors' :
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
    }

    class { 'rsync::server' :
      gid        => 'root',
      uid        => 'root',
      use_chroot => 'yes',
      use_xinetd => false,
    }

    rsync::server::module{ 'mirrors':
      comment         => 'Fuel rsync mirror',
      uid             => 'nobody',
      gid             => 'nogroup',
      list            => 'yes',
      lock_file       => '/var/run/rsync_mirrors.lock',
      max_connections => 100,
      path            => '/var/www/mirrors',
      read_only       => 'yes',
      write_only      => 'no',
      require         => File['/var/www/mirrors'],
    }

    rsync::server::module{ 'mirrors-sync':
      comment         => 'Fuel sync',
      uid             => 'www-data',
      gid             => 'www-data',
      hosts_allow     => $mirror_sync_hosts_allow,
      hosts_deny      => ['*'],
      list            => 'yes',
      lock_file       => '/var/run/rsync_mirrors_sync.lock',
      max_connections => 100,
      path            => '/var/www/mirrors',
      read_only       => 'no',
      write_only      => 'no',
      require         => File['/var/www/mirrors'],
    }

    if ($mirror_apply_firewall_rules) {
      include firewall_defaults::pre
      create_resources(firewall, $mirror_firewall_allow_sources, {
        dport   => 873,
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      })
    }
  }
}
