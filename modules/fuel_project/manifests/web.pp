# Class: fuel_project::web
#
class fuel_project::web {
  class { '::fuel_project::nginx' :}
  class { '::fuel_project::common' :}
  class { '::fuel_project::landing_page' :}

  zabbix::item { 'nginx' :
    content => 'puppet:///modules/fuel_project/web/zabbix/nginx_items.conf',
  }
}
