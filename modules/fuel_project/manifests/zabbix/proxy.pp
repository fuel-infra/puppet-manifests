# Class: fuel_project::zabbix::proxy
#
class fuel_project::zabbix::proxy {
  class { '::fuel_project::common' :}
  class { '::zabbix::proxy' :}
}
