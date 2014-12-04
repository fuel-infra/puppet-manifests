# Anonymous statistics analytic
class fuel_stats::migration (
  $development            = false,
  $psql_host              = $fuel_stats::params::psql_host,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
) inherits fuel_stats::params {
  file { '/etc/migration.yaml':
    ensure  => 'file',
    content => template('fuel_stats/migration.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  if $development {
    $migrate_cmd = '/var/www/migration/migration/manage_migration.py -c /etc/migration.yaml'
    fuel_stats::dev { 'migration':
      before => [
        Exec['clear_indices'],
        Cron['migration'],
      ]
    }
  } else {
    $migrate_cmd = '/usr/bin/manage_migration.py -c /etc/migration.yaml'
    package { 'fuel-stats-migration' :
      ensure => 'installed',
      before => [
        Exec['clear_indices'],
        Cron['migration'],
      ]
    }
  }

  if ! defined(File['/var/log/fuel-stats']) {
    file { '/var/log/fuel-stats' :
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  cron { 'migration':
    command => "${migrate_cmd} migrate",
    user    => 'root',
    hour    => '*',
    minute  => ['0', '15', '30', '45'],
  }

  exec { 'clear_indices':
    command => "${migrate_cmd} clear_indices",
    require => [
      File['/var/log/fuel-stats'],
      File['/etc/migration.yaml'],
    ]
  }

  exec { 'create_indices':
    command => "${migrate_cmd} create_indices",
    require => [
      Exec['clear_indices'],
    ],
  }
}
