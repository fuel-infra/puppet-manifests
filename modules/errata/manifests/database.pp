# Class: errata::database
#
class errata::database (
  $database_engine   = $::errata::params::database_engine,
  $database_host     = $::errata::params::database_host,
  $database_name     = $::errata::params::database_name,
  $database_password = $::errata::params::database_password,
  $database_port     = $::errata::params::database_port,
  $database_user     = $::errata::params::databases_user,
) inherits ::errata::params {
  if($database_engine == 'django.db.backends.mysql') {
    class { '::mysql::server' :}
    class { '::mysql::client' :}
    class { '::mysql::server::account_security' :}
    ::mysql::db { $database_name :
      user     => $database_user,
      password => $database_password,
      host     => $database_host,
      grant    => ['all'],
      charset  => 'utf8',
      require  => [
        Class['::mysql::server'],
        Class['::mysql::server::account_security'],
      ],
    }
  } else {
    fail("Engine ${database_engine} is not supported yet")
  }
}
