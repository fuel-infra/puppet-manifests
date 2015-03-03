# Class: fuel_project::roles::ns
#
class fuel_project::roles::ns {
  class { '::fuel_project::common' :}
  class { '::fuel_project::apps::bind' :}
}
