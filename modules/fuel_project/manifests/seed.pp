# Class: fuel_project::seed
#
class fuel_project::seed (
  $apply_firewall_rules = false,
  $client_max_body_size = '5G',
  $external_host = false,
  $firewall_allow_sources = {},
  $seed_dir = '/var/www/seed',
  $seed_port = 17333,
  $service_fqdn = "seed.${::fqdn}",
  $tracker_apply_firewall_rules = false,
  $tracker_firewall_allow_sources = {},
) {
  class { '::opentracker' :
    apply_firewall_rules   => $tracker_apply_firewall_rules,
    firewall_allow_sources => $tracker_firewall_allow_sources,
  }

  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  nginx::resource::vhost { 'seed' :
    ensure      => 'present',
    autoindex   => 'off',
    www_root    => $seed_dir,
    server_name => [$service_fqdn, "seed.${::fqdn}"]
  }

  if (!defined(File['/var/www'])) {
    file { '/var/www' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      before => File[$seed_dir]
    }
  }

  file { $seed_dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Class['nginx'],
  }

  $storage_dirs = [
    "${seed_dir}/fuelweb-iso",
  ]

  ensure_packages('python-seed-cleaner')

  file { '/usr/local/bin/seed-downloads-cleanup.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('fuel_project/common/seed-downloads-cleanup.sh.erb'),
    require => Package['python-seed-cleaner'],
  }

  cron { 'seed-downloads-cleanup' :
    command => '/usr/local/bin/seed-downloads-cleanup.sh | logger -t seed-downloads-cleanup',
    user    => root,
    hour    => '*/4',
    minute  => 0,
    require => File['/usr/local/bin/seed-downloads-cleanup.sh'],
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
