# Anonymous statistics collector
class fuel_project::statistics::collector (
  $ldap                   = false,
  $development            = false,
  $firewall_enable        = false,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
  $psql_user              = 'collector',
  $psql_pass              = 'collector',
  $psql_db                = 'collector',
  $psql_port              = 5432,
  $analytic_ip            = '127.0.0.1',
  $service_port           = 443,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $ssl_key_file           = '',
  $ssl_key_file_contents  = '',
  $ssl_cert_file          = '',
  $ssl_cert_file_contents = '',
) {
  class { '::fuel_project::common':
    ldap          => $ldap,
    external_host => $firewall_enable,
  }

  class { 'fuel_stats::collector':
    nginx_conf             => $nginx_conf,
    nginx_conf_link        => $nginx_conf_link,
    ssl_key_file           => $ssl_key_file,
    ssl_key_file_contents  => $ssl_key_file_contents,
    ssl_cert_file          => $ssl_cert_file,
    ssl_cert_file_contents => $ssl_cert_file_contents,
  }

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
