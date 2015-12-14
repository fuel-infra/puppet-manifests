# Class: gerrit::mysql
#
# This class is very simple wrapper to deploy a database server and create
# an account for gerrit with given parameters.
#
# Parameters:
#   [*database_name*] - name of database
#   [*database_password*] - database user password
#   [*database_user*] - database user name
#
class gerrit::mysql (
  $database_name     = '',
  $database_password = '',
  $database_user     = '',
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
