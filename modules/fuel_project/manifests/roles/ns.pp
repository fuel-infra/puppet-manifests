# Class: fuel_project::roles::ns
#
class fuel_project::roles::ns {
  class { '::fuel_project::common' :}
  class { '::bind' :}
  ::bind::server::conf { '/etc/bind/named.conf' :}
}
