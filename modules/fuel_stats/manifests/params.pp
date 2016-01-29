# Class: fuel_stats::params
#
# This class stores default parameters for other fuel_stats classes.
#
# Please see parameters description in top modules.
#
class fuel_stats::params(
  $analytics_ip           = '127.0.0.1',

  # development parameters
  $auto_update            = false,
  $development            = false,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',

  # pgsql setting for tests and analytics
  $psql_host              = 'fuel-collect.test.local',
  $psql_user              = 'collector',
  $psql_pass              = 'collector',
  $psql_db                = 'collector',

  # common params
  $http_port              = 80,
  $https_port             = 443,
  $limit_conn             = undef,
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
) { }
