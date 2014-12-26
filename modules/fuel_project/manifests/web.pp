# Class: fuel_project::web
#
class fuel_project::web {
  class { '::fuel_project::common' :}
  class { '::fuel_project::landing_page' :}
}
