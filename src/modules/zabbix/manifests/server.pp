class zabbix::server {
  include zabbix::params

  $config = $zabbix::params::server_config
  $packages = $zabbix::params::server_packages
  $service = $zabbix::params::server_service

  $innodb_buffer_pool_size = $zabbix::params::innodb_buffer_pool_size
  $innodb_file_per_table = $zabbix::params::innodb_file_per_table
  $max_connections = $zabbix::params::max_connections

  package { $packages :
    ensure => 'present',
  }

  class { '::mysql::server':
    package_name     => 'percona-server-server',
    root_password    => 'r00tme',
    override_options => {
      'mysqld' => {
        'innodb_buffer_pool_size' => $innodb_buffer_pool_size,
        'innodb_file_per_table' => $innodb_file_per_table,
        'innodb_flush_method' => 'O_DIRECT',
        'join_buffer_size' => '256M',
        'lock_wait_timeout' => 120,
        'log_queries_not_using_indexes' => 1,
        'max_connections' => $max_connections,
        'query_cache_type' => 1,
        'read_rnd_buffer_size' => '4M',
        'slow_query_log' => 1,
        'slow_query_log_file' => '/var/log/mysql/slow.log',
        'sort_buffer_size' => '4M',
        'table_open_cache' => '256M',
        'thread_cache_size' => '4M',
      },
    },
    users => {
      'zabbix@localhost' => {
        ensure => 'present',
        password_hash => '*DEEF4D7D88CD046ECA02A80393B7780A63E7E789',
      }
    },
    databases => {
      'zabbix' => {
        ensure => 'present',
        charset => 'utf8',
      }
    },
    grants => {
      'zabbix@localhost/zabbix.*' => {
        ensure => 'present',
        options => ['GRANT'],
        privileges => ['ALTER', 'CREATE', 'INDEX', 'SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        table => 'zabbix.*',
        user => 'zabbix@localhost',
      }
    }
  }

  exec { 'flag-installation-complete' :
    command => 'touch /etc/zabbix/zabbix_server_installed.flag',
    provider => 'shell',
  }

  exec { 'import-zabbix-fixtures' :
    command => 'zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql -uzabbix -pzabbix zabbix',
    provider => 'shell',
    creates => '/etc/zabbix/zabbix_server_installed.flag',
  }

  exec { 'load-zabbix-initial-data' :
    command => 'zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql -uzabbix -pzabbix zabbix',
    provider => 'shell',
    creates => '/etc/zabbix/zabbix_server_installed.flag',
  }

  exec { 'load-zabbix-images' :
    command => 'zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql -uzabbix -pzabbix zabbix',
    provider => 'shell',
    creates => '/etc/zabbix/zabbix_server_installed.flag',
  }

  file { $config :
    path => $config,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/zabbix_server.conf.erb'),
  }

  file { 'ping-handle' :
    path => '/usr/share/zabbix/ping.php',
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('zabbix/ping.php.erb'),
  }

  service { $service :
    ensure => 'running',
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  Class['dpkg']->
    Package[$packages]->
    Class['::mysql::server']->
    Exec['import-zabbix-fixtures']->
    Exec['load-zabbix-images']->
    Exec['load-zabbix-initial-data']->
    File[$config]~>
    File['ping-handle']->
    Service[$service]->
    Exec['flag-installation-complete']
}
