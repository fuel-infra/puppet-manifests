# Anonymous statistics collector
class fuel_project::statistics::collector (
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
  $migration_ip           = '127.0.0.1',
) inherits fuel_project::statistics::params {
  class { '::fuel_project::common':
    ldap          => $ldap,
    external_host => $firewall_enable,
  }

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

  class { 'fuel_stats::collector':
    development            => $development,
    firewall_enable        => $firewall_enable,
    firewall_allow_sources => $firewall_allow_sources,
    firewall_deny_sources  => $firewall_deny_sources,
    ssl                    => $ssl,
    ssl_cert_file          => $ssl_cert_file,
    ssl_key_file           => $ssl_key_file,
    migration_ip           => $migration_ip,
    service_port           => $real_service_port,
  }

  if ($firewall_enable) {
    include firewall_defaults::pre
    firewall { '1000 Allow analytic psql connection' :
      ensure  => present,
      source  => "${migration_ip}/32",
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
