# Class: fuel_project::zuul
#
# This class deploys Zuul Zabbix items.
#
class fuel_project::zuul {
  ensure_resource('class', 'zabbix::agent')
  ensure_packages('config-zabbix-agent-zuul-item')
}
