# Class: fuel_project::web
#
class fuel_project::web {
  class { '::fuel_project::nginx' :}
  class { '::fuel_project::common' :}
  class { '::landing_page' :}
}
