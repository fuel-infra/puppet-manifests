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
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      apply_firewall_rules => $apply_firewall_rules,
      create_www_dir       => true,
    }
  }
  include ::nginx::service
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
  }~>
  Service['nginx']

  file { '/etc/nginx/sites-enabled/seed.conf' :
    ensure  => 'link',
    target  => '/etc/nginx/sites-available/seed.conf',
    require => File['/etc/nginx/sites-available/seed.conf'],
  }~>
  Service['nginx']

  file { $seed_dir :
    ensure  => 'directory',
    owner   => 'www-data',
    group   => 'www-data',
    require => Class['nginx'],
  }

  $storage_dirs = [
    "${seed_dir}/fuelweb-iso",
  ]

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
