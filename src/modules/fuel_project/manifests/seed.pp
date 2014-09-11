# Class: fuel_project::seed
#
class fuel_project::seed (
  $external_host = false,
  $service_fqdn = $::fqdn,
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $seed_dir = '/var/www',
  $client_max_body_size = '5G',
  $seed_port = 17333,
  $tracker_apply_firewall_rules = false,
  $tracker_firewall_allow_sources = [],
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
}
