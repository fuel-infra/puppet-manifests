# Class: fuel_project::apps::monitoring::mysql::server
#
# This class deploys MySQL checks for Zabbix Agent. MySQL credentials are copied
# from /root/.my.cnf file.
#
# Parameters:
#   [*content*] - content of configuration file with Zabbix item
#
class fuel_project::apps::monitoring::mysql::server {
  zabbix::item { 'mysql' :
    content => 'puppet:///modules/fuel_project/apps/monitoring/mysql/mysql_items.conf',
  }

  file { '/var/lib/zabbix/.my.cnf' :
    ensure  => 'present',
    source  => '/root/.my.cnf',
    require => Class['::mysql::server'],
    owner   => 'zabbix',
    group   => 'zabbix',
    mode    => '0600',
  }
}
