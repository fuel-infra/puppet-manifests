# Define: zabbix::item
#
define zabbix::item (
  $items = [],
  $raw_content = '',
  $content = false,
) {
  include zabbix::agent::service
  include zabbix::params

  $service = $::zabbix::params::agent_service

  if $title {
    file { "/etc/zabbix/zabbix_agentd.conf.d/${title}.conf" :
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => $content,
      require => Class['zabbix::agent'],
      notify  => Service[$service]
    }
  } else {
    fail('zabbix::item invoked with empty name argument')
  }
}
