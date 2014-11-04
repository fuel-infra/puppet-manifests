# Anonymous statistics test suite
class fuel_stats::tests (
  $psql_user       = $fuel_stats::params::psql_user,
  $psql_pass       = $fuel_stats::params::psql_user,
  $psql_db         = $fuel_stats::params::psql_user,
) inherits fuel_stats::params {
    $packages = [
      'python-tox',
    ]
    ensure_packages($packages)

    if (!defined(Class['postgresql::server'])) {
      class { 'postgresql::server' : }
    }
    postgresql::server::db { $psql_db :
      user     => $psql_user,
      password => postgresql_password($psql_user, $psql_pass),
    }

    file { '/var/log/fuel-stats' :
      ensure  => directory,
      owner   => 'jenkins',
      require => User['jenkins'],
    }
}
