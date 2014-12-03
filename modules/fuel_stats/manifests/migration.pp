# Anonymous statistics analytic
class fuel_stats::migration (
  $development            = false,
  $psql_host              = $fuel_stats::params::psql_host,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
) inherits fuel_stats::params {
  $migrate_cmd = '/usr/bin/manage_migration.py -c /etc/migration.yaml'

  file { '/etc/migration.yaml':
    ensure  => 'file',
    content => template('fuel_stats/migration.yaml.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  cron { 'migration':
    command => "${migrate_cmd} migrate",
    user    => 'root',
    hour    => '*',
    minute  => ['0', '15', '30', '45'],
    require => Package['fuel-stats-migration']
  }

  package { 'fuel-stats-migration' :
    ensure => 'installed',
  }

  exec { 'clear_indices':
    command => "${migrate_cmd} clear_indices",
    require => [
      File['/etc/migration.yaml'],
      Package['fuel-stats-migration'],
    ],
  }

  exec { 'create_indices':
    command => "${migrate_cmd} create_indices",
    require => Exec['clear_indices'],
  }
}
