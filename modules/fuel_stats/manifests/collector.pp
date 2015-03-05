# Anonymous statistics collector
class fuel_stats::collector (
  $development            = $fuel_stats::params::development,
  $auto_update            = $fuel_stats::params::auto_update,
  $fuel_stats_repo        = $fuel_stats::params::fuel_stats_repo,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
  $migration_ip           = '127.0.0.1',
  $http_port              = $fuel_stats::params::http_port,
  $https_port             = $fuel_stats::params::https_port,
  $ssl                    = false,
  $ssl_cert_file          = '',
  $ssl_key_file           = '',
  $firewall_enable        = $fuel_stats::params::firewall_enable,
  $firewall_rules         = {},
) inherits fuel_stats::params {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      http_cfg_append => {
        'limit_conn_zone' => '$binary_remote_addr zone=addr:10m'
      }
    }
  }
  $limit_conn = { 'limit_conn' => 'addr 1' }

  if $ssl {
    ::nginx::resource::vhost { 'collector' :
      ensure              => 'present',
      ssl                 => true,
      ssl_port            => $https_port,
      listen_port         => $https_port,
      ssl_cert            => $ssl_cert_file,
      ssl_key             => $ssl_key_file,
      server_name         => [$::fqdn],
      uwsgi               => '127.0.0.1:7932',
      location_cfg_append => merge($firewall_rules, $limit_conn),
    }
    ::nginx::resource::vhost { 'collector-redirect' :
      ensure              => 'present',
      listen_port         => $http_port,
      www_root            => '/var/www',
      server_name         => [$::fqdn],
      location_cfg_append => {
        'rewrite'    => "^ https://\$server_name:${https_port}\$request_uri? permanent",
        'limit_conn' => 'addr 1',
      },
    }
  } else {
    ::nginx::resource::vhost { 'collector' :
      ensure              => 'present',
      listen_port         => $http_port,
      server_name         => [$::fqdn],
      uwsgi               => '127.0.0.1:7932',
      location_cfg_append => merge($firewall_rules, $limit_conn),
    }
  }

  user { 'collector':
    ensure     => present,
    home       => '/var/www/collector',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  # Postgresql configuration
  if ! defined(Class['postgresql::server']) {
    class { 'postgresql::server':
      listen_addresses           => '*',
      ip_mask_deny_postgres_user => '0.0.0.0/0',
      ip_mask_allow_all_users    => "${migration_ip}/32",
      ipv4acls                   => [
        "hostssl ${psql_db} ${psql_user} ${migration_ip}/32 cert",
        "host ${psql_db} ${psql_user} 127.0.0.1/32 md5",
        "local ${psql_db} ${psql_user} md5",
      ],
    }
  }
  postgresql::server::db { $psql_db:
    user     => $psql_user,
    password => postgresql_password($psql_user, $psql_pass),
  }

  file { '/etc/collector.py':
    ensure  => 'file',
    content => template('fuel_stats/collect.py.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  if $development {
    # development configuration
    fuel_stats::dev { 'collector':
      require => User['collector'],
    }
    # uwsgi configuration
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      env      => 'COLLECTOR_SETTINGS=/etc/collector.py',
      chdir    => '/var/www/collector/collector',
      module   => 'collector.api.app_test',
      callable => 'app',
      require  => [
        File['/etc/collector.py'],
        File['/var/log/fuel-stats'],
        Fuel_stats::Dev['collector'],
      ],
    }
    $src_path = '/var/www/collector/collector'
    exec { 'upgrade-collector-db':
      command     => "${src_path}/manage_collector.py --mode prod db upgrade -d .",
      environment => 'COLLECTOR_SETTINGS=/etc/collector.py',
      cwd         => "${src_path}/collector/api/db/migrations",
      require     => [
        Fuel_stats::Dev['collector'],
        File['/etc/collector.py'],
        Postgresql::Server::Db[$psql_db],
      ]
    }
  } else {
    # production configuration
    package { 'fuel-stats-collector' :
      ensure  => 'installed',
      require => [
        File['/etc/collector.py'],
        Postgresql::Server::Db[$psql_db],
      ],
      notify  => Service['uwsgi'],
    }
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      env      => 'COLLECTOR_SETTINGS=/etc/collector.py',
      chdir    => '/usr/lib/python2.7/dist-packages',
      module   => 'collector.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/collector.py'],
        File['/var/log/fuel-stats'],
        User['collector'],
      ],
    }
  }

  if ! defined(File['/var/log/fuel-stats']) {
    file { '/var/log/fuel-stats':
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
  }

  file { '/var/log/fuel-stats/collector.log':
    ensure => 'present',
    mode   => '0644',
    owner  => 'collector',
    group  => 'collector',
  }
}
