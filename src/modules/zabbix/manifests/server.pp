class zabbix::server {
  include zabbix::params

  $config = $zabbix::params::server_config
  $packages = $zabbix::params::server_packages
  $service = $zabbix::params::server_service

  $innodb_buffer_pool_size = $zabbix::params::innodb_buffer_pool_size
  $innodb_file_per_table = $zabbix::params::innodb_file_per_table
  $max_connections = $zabbix::params::max_connections

  package { $packages :
    ensure => present,
  }

  class { '::mysql::server':
    root_password    => 'r00tme',
    override_options => {
      'mysqld' => {
        'innodb_file_per_table' => $innodb_file_per_table,
        'max_connections' => $max_connections,
        'innodb_buffer_pool_size' => $innodb_buffer_pool_size,
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
        ensure => present,
        charset => 'utf8',
      }
    },
    grants => {
      'zabbix@localhost/zabbix.*' => {
        ensure => present,
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

  service { $service :
    ensure => running,
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
    Service[$service]->
    Exec['flag-installation-complete']
}
