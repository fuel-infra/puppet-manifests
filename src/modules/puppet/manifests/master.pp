class puppet::master {
  include puppet::params

  include puppet::config
  include virtual::repos

  $allowed_ips = $puppet::params::allowed_ips
  $packages = $puppet::params::master_packages
  $service = $puppet::params::master_service

  realize Virtual::Repos::Repository['puppetlabs']
  realize Virtual::Repos::Repository['puppetlabs-deps']

  package { $packages :
    ensure => present,
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  if $external_host {
    $port = 8140
    each($allowed_ips) |$ip| {
      firewall { "1000 allow puppetmaster connections - ${ip}:${port}" :
        dport => $port,
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
