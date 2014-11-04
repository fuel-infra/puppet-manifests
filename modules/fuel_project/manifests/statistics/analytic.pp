# Anonymous statistics analytic
class fuel_project::statistics::analytic (
  $development            = false,
  $service_port           = 443,
  $firewall_enable        = false,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
  $ldap                   = false,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $ssl_key_file           = '',
  $ssl_key_file_contents  = '',
  $ssl_cert_file          = '',
  $ssl_cert_file_contents = '',
) {
  class { '::fuel_project::common':
    external_host => $firewall_enable,
    ldap          => $ldap,
  }

  class { 'fuel_stats::analytic':
    service_port           => $service_port,
    firewall_enable        => $firewall_enable,
    nginx_conf             => $nginx_conf,
    nginx_conf_link        => $nginx_conf_link,
    ssl_key_file           => $ssl_key_file,
    ssl_key_file_contents  => $ssl_key_file_contents,
    ssl_cert_file          => $ssl_cert_file,
    ssl_cert_file_contents => $ssl_cert_file_contents,
  }

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
