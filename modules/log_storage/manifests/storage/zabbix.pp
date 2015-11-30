# class log_storage::storage::zabbix
#
class log_storage::storage::zabbix (
  $zabbix_items_package = 'config-zabbix-agent-log-storage-item',
) {

  package { $zabbix_items_package :
    ensure  => 'present',
    require => Package['curl'],
  }

  ensure_resource('package', $zabbix_items_package)

}
