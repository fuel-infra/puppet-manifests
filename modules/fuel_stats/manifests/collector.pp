# Anonymous statistics collector
class fuel_stats::collector (
  $development            = $fuel_stats::params::development,
  $auto_update            = $fuel_stats::params::auto_update,
  $fuel_stats_repo        = $fuel_stats::params::fuel_stats_repo,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
  $migration_ip           = '127.0.0.1',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $service_port           = $fuel_stats::params::service_port,
  $ssl                    = false,
  $ssl_cert_file          = '',
  $ssl_key_file           = '',
  $firewall_enable        = $fuel_stats::params::firewall_enable,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
) inherits fuel_stats::params {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' : }
  }

  # nginx configuration
  # /etc/nginx/sites-available/fuel-collector.conf
  # virtual host file for nginx
  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_stats/fuel-collector.conf.erb'),
  }

  # /etc/nginx/sites-enabled/fuel-collector.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure  => 'link',
    target  => $nginx_conf,
    require => File[$nginx_conf],
    notify  => Service['nginx']
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
  } else {
    # production configuration
    package { 'fuel-stats-collector' :
      ensure  => 'installed',
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

  file { '/var/log/fuel-stats':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'collector',
    group  => 'collector',
  }
}
