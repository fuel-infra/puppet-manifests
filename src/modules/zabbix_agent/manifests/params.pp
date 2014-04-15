class zabbix_agent::params {
  $checks = [
    'hardware.conf',
    'software.conf',
  ]
  $packages = ['zabbix-agent']
  $service = 'zabbix-agent'
  $zabbix_nets = [
    '172.18.0.0/16',
    '91.218.144.129/32',
  ]
}
