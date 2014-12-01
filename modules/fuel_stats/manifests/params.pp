# default params for fuel_stats
class fuel_stats::params(
  # development parameters
  $development            = false,
  $auto_update            = false,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',

  # pgsql setting for tests and analytics
  $psql_host              = 'fuel-collect.test.local',
  $psql_user              = 'collector',
  $psql_pass              = 'collector',
  $psql_db                = 'collector',

  $firewall_enable        = false,

  $service_port           = 80,
) { }
