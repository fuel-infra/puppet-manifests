# Anonymous statistics analytic
class fuel_project::statistics::analytic (
  $development            = $fuel_project::statistics::params::development,
  $ldap                   = $fuel_project::statistics::params::ldap,
  $firewall_enable        = $fuel_project::statistics::params::firewall_enable,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
  $ssl_cert_file          = '',
  $ssl_cert_file_contents = '',
  $ssl_key_file           = '',
  $ssl_key_file_contents  = '',
  $service_port           = $fuel_project::statistics::params::service_port,
) inherits fuel_project::statistics::params {
  if $ssl_cert_file != '' and $ssl_key_file != '' {
    file { $ssl_key_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
    }
    file { $ssl_cert_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
    }
    $ssl = true
  } else {
    $ssl = false
  }

  if ! $service_port {
    if $ssl { $real_service_port = 443 }
    else    { $real_service_port = 80 }
  } else {
    $real_service_port = $service_port
  }

  class { '::fuel_project::common':
    external_host => $firewall_enable,
    ldap          => $ldap,
  }

  class { 'fuel_stats::analytic':
    firewall_enable        => $firewall_enable,
    firewall_allow_sources => $firewall_allow_sources,
    firewall_deny_sources  => $firewall_deny_sources,
    ssl                    => $ssl,
    ssl_cert_file          => $ssl_cert_file,
    ssl_key_file           => $ssl_key_file,
    service_port           => $real_service_port,
  }

  class { 'fuel_stats::migration': }

  if ($firewall_enable) {
    include firewall_defaults::pre
    if ($firewall_allow_sources != {}) {
      create_resources(firewall, $firewall_allow_sources, {
        ensure  => present,
        port    => [80, $real_service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      })
    } else {
      firewall { '1000 Allow http and https collector connection' :
        ensure  => present,
        port    => [80, $real_service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }
}
