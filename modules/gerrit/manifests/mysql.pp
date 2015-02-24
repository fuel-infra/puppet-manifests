# == Class: gerrit::mysql
#
class gerrit::mysql (
  $database_name = '',
  $database_user = '',
  $database_password = '',
) {

  class { '::mysql::server' :}
  class { '::mysql::client' :}
  class { '::mysql::server::account_security' :}

  ::mysql::db { $database_name :
    user     => $database_user,
    password => $database_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['::mysql::server'],
      Class['::mysql::server::account_security'],
    ],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
