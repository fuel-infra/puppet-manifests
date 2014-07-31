class puppet::master {
  include puppet::params

  include puppet::config
  include virtual::repos

  $packages = $puppet::params::master_packages
  $service = $puppet::params::master_service

  realize Virtual::Repos::Repository['puppetlabs']
  realize Virtual::Repos::Repository['puppetlabs-deps']

  realize Package[$packages]

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  if $external_host {
    $firewall = hiera_hash('firewall')

    $port = 8140
    $proto = 'tcp'

    $allowed_networks = $firewall['known_networks'] +
      $firewall['external_hosts'] +
      $firewall['internal_networks']

    each($allowed_networks) |$ip| {
      firewall { "1000 allow puppetmaster connections - src ${ip} ; dst ${proto}/${port}" :
        dport => $port,
        proto => $proto,
        source => $ip,
        action => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }

  Package[$packages]->
    Class['puppet::config']~>
    Service[$service]
}
