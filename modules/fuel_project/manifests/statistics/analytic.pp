# Anonymous statistics analytic
class fuel_project::statistics::analytic (
  $development            = $fuel_project::statistics::params::development,
  $ldap                   = $fuel_project::statistics::params::ldap,
  $firewall_enable        = $fuel_project::statistics::params::firewall_enable,
  $firewall_allow_sources = {},
  $ssl_cert_file          = '/etc/ssl/analytic.crt',
  $ssl_cert_file_contents = '',
  $ssl_key_file           = '/etc/ssl/analytic.key',
  $ssl_key_file_contents  = '',
  $http_port              = $fuel_project::statistics::params::http_port,
  $https_port             = $fuel_project::statistics::params::https_port,
) inherits fuel_project::statistics::params {
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

  if ! defined (Class['fuel_project::common']) {
    class { '::fuel_project::common':
      ldap          => $ldap,
      external_host => $firewall_enable,
    }
  }

  class { 'fuel_stats::analytic':
    development     => $development,
    firewall_enable => $firewall_enable,
    ssl             => $ssl,
    http_port       => $http_port,
    https_port      => $https_port,
    ssl_cert_file   => $ssl_cert_file,
    ssl_key_file    => $ssl_key_file,
  }

  class { 'fuel_stats::migration':
    development => $development,
    require     => [
      Class['fuel_stats::analytic'],
      Service['elasticsearch'],
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
