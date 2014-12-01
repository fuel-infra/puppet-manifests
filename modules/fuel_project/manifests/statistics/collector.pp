# Anonymous statistics collector
class fuel_project::statistics::collector (
  $development            = false,
  $ldap                   = false,
  $firewall_enable        = false,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
) {
  class { '::fuel_project::common':
    ldap          => $ldap,
    external_host => $firewall_enable,
  }

  class { 'fuel_stats::collector': }

  if ($firewall_enable) {
    include firewall_defaults::pre
    firewall { '1000 Allow analytic psql connection' :
      ensure  => present,
      source  => "${analytic_ip}/32",
      dport   => $psql_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
    if ($firewall_deny_sources != {}) {
      create_resources('firewall', $firewall_deny_sources, {
        ensure  => present,
        dport   => $service_port,
        proto   => 'tcp',
        action  => 'reject',
        require => Class['firewall_defaults::pre'],
      })
    } else {
      firewall { '1000 Allow https collector connection' :
        ensure  => present,
        dport   => $service_port,
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
