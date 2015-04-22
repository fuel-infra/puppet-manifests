# Anonymous statistics collector
class fuel_project::roles::stats_collector (
  $analytics_ip           = '127.0.0.1',
  $development            = false,
  $firewall_enable        = false,
  $firewall_deny_sources  = {},
  $http_port              = 80,
  $https_port             = 443,
  $ldap                   = false
) {
  if ( ! defined (Class['::fuel_project::common']) ) {
    class { '::fuel_project::common':
      ldap          => $ldap,
      external_host => $firewall_enable,
    }
  }

  class { '::fuel_project::nginx' : }

  class { '::fuel_stats::collector' :
    development => $development,
    http_port   => $http_port,
    https_port  => $https_port,
  }

  if ($firewall_enable) {
    include firewall_defaults::pre
    firewall { '1000 Allow analytic psql connection' :
      ensure  => present,
      source  => "${analytics_ip}/32",
      dport   => $psql_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
    if ($firewall_deny_sources != {}) {
      create_resources('firewall', $firewall_deny_sources, {
        ensure  => present,
        dport   => [$http_port, $https_port],
        proto   => 'tcp',
        action  => 'reject',
        require => Class['firewall_defaults::pre'],
      })
    }
    firewall { "1000 Allow ${http_port},  ${https_port} collector connection" :
      ensure  => present,
      dport   => [$http_port, $https_port],
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }
}
