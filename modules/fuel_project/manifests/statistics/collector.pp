# Anonymous statistics collector
class fuel_project::statistics::collector (
  $development            = $fuel_project::statistics::params::development,
  $ldap                   = $fuel_project::statistics::params::ldap,
  $firewall_enable        = $fuel_project::statistics::params::firewall_enable,
  $firewall_deny_sources  = {},
  $ssl_cert_file          = '/etc/ssl/collector.crt',
  $ssl_cert_file_contents = '',
  $ssl_key_file           = '/etc/ssl/collector.key',
  $ssl_key_file_contents  = '',
  $http_port              = $fuel_project::statistics::params::http_port,
  $https_port             = $fuel_project::statistics::params::https_port,
  $migration_ip           = '127.0.0.1',
) inherits fuel_project::statistics::params {
  if ! defined (Class['fuel_project::common']) {
    class { '::fuel_project::common':
      ldap          => $ldap,
      external_host => $firewall_enable,
    }
  }

  if $ssl_cert_file_contents != '' and $ssl_key_file_contents != '' {
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

  class { 'fuel_stats::collector':
    development   => $development,
    ssl           => $ssl,
    http_port     => $http_port,
    https_port    => $https_port,
    ssl_cert_file => $ssl_cert_file,
    ssl_key_file  => $ssl_key_file,
    migration_ip  => $migration_ip,
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
