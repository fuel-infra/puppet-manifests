class zabbix_agent::params {
  $checks = [
    'hardware.conf',
    'software.conf',
  ]
  $packages = ['zabbix-agent']
  $service = 'zabbix-agent'
}
