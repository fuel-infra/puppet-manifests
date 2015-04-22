# Anonymous statistics analytic
class fuel_project::roles::stats (
  $development            = false,
  $firewall_allow_sources = {},
  $firewall_enable        = false,
  $http_port              = 80,
  $https_port             = 443,
  $ldap                   = false,
) {
  if ( ! defined (Class['::fuel_project::common']) ) {
    class { '::fuel_project::common' :
      ldap          => $ldap,
      external_host => $firewall_enable,
    }
  }

  class { '::fuel_project::nginx' : }

  class { '::fuel_stats::analytic' :
    development     => $development,
    firewall_enable => $firewall_enable,
    http_port       => $http_port,
    https_port      => $https_port,
  }

  class { '::fuel_stats::migration' :
    development => $development,
    require     => [
      Class['::fuel_stats::analytic'],
    ]
  }

  if ($firewall_enable) {
    include firewall_defaults::pre
    if ($firewall_allow_sources != {}) {
      create_resources(firewall, $firewall_allow_sources, {
        ensure  => present,
        port    => [$http_port, $https_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      })
    } else {
      firewall { '1000 Allow http and https collector connection' :
        ensure  => present,
        port    => [$http_port, $https_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
