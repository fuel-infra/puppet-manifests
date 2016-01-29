# Class: fuel_project::roles::zabbix::proxy
#
# This class deploys Zabbix proxy role.
#
class fuel_project::roles::zabbix::proxy {
  class { '::fuel_project::common' :}
  class { '::zabbix::proxy' :}
}
