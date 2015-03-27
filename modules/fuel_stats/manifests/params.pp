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

  $analytics_ip           = '127.0.0.1',

  $http_port              = 80,
  $https_port             = 443,
) { }
