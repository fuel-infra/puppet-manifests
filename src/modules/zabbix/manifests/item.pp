# Class: zabbix::item
#
class zabbix::item (
  $name = '',
  $items = [],
  $raw_content = false,
  $template = false
) {
  include zabbix::agent::service
  include zabbix::params

  $service = $::zabbix::params::agent_service

  if $name {
    file { "/etc/zabbix/zabbix_agentd.conf.d/${name}.conf" :
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template(
        $template ? {
          false   => 'zabbix/item.erb',
          default => $template
        }),
      require => Class['zabbix::agent'],
      notify  => Service[$service]
    }
  } else {
    fail('zabbix::item invoked with empty name argument')
  }
}
