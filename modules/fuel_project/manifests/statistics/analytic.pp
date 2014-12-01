# Anonymous statistics analytic
class fuel_project::statistics::analytic (
  $development            = false,
  $firewall_enable        = false,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
  $ldap                   = false,
) {
  class { '::fuel_project::common':
    external_host => $firewall_enable,
    ldap          => $ldap,
  }

  class { 'fuel_stats::analytic':
    firewall_enable        => $firewall_enable,
  }

  class { 'fuel_stats::migration': }

  if ($firewall_enable) {
    include firewall_defaults::pre
    if ($firewall_allow_sources != {}) {
      create_resources(firewall, $firewall_allow_sources, {
        ensure  => present,
        port    => [80, $service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      })
    } else {
      firewall { '1000 Allow http and https collector connection' :
        ensure  => present,
        port    => [80, $service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
