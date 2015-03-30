# class fuel_stats::db
class fuel_stats::db (
  $install_psql           = false,
  $psql_host              = $fuel_stats::params::psql_host,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
  $analytics_ip           = $fuel_stats::params::analytics_ip,
) inherits fuel_stats::params {
  if ($install_psql) {
    # Postgresql configuration
    if ! defined(Class['postgresql::server']) {
      class { 'postgresql::server':
        listen_addresses           => '*',
        ip_mask_deny_postgres_user => '0.0.0.0/0',
        ip_mask_allow_all_users    => "${analytics_ip}/32",
        ipv4acls                   => [
          "hostssl ${psql_db} ${psql_user} ${analytics_ip}/32 cert",
          "host ${psql_db} ${psql_user} 127.0.0.1/32 md5",
          "local ${psql_db} ${psql_user} md5",
        ],
      }
    }
    postgresql::server::db { $psql_db:
      user     => $psql_user,
      password => postgresql_password($psql_user, $psql_pass),
    }
  }
}
