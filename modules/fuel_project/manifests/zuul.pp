# Class: fuel_project::zuul
#
class fuel_project::zuul {
  ensure_resource('class', 'zabbix::agent')
  ensure_packages('config-zabbix-agent-zuul-item')
}
