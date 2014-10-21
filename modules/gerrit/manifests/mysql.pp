# == Class: gerrit::mysql
#
class gerrit::mysql(
  $mysql_root_password = '',
  $database_name = '',
  $database_user = '',
  $database_password = '',
) {

  class { '::mysql::server':
    package_name     => 'percona-server-server',
    override_options => {
      'root_password'                 => $mysql_root_password,
      'default_engine'                => 'InnoDB',
      'bind_address'                  => '127.0.0.1',
      'lock_wait_timeout'             => 120,
      'log_queries_not_using_indexes' => 1,
      'slow_query_log'                => 1,
      'slow_query_log_file'           => '/var/log/mysql/slow.log',
    }
  }

  class { 'mysql::client':
    package_name => 'percona-server-client-5.6',
  }

  include mysql::server::account_security

  mysql::db { $database_name:
    user     => $database_user,
    password => $database_password,
    host     => 'localhost',
    grant    => ['all'],
    charset  => 'utf8',
    require  => [
      Class['::mysql::server'],
      Class['mysql::server::account_security'],
    ],
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
