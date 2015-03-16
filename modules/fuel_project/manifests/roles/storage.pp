# Class: fuel_project::roles::storage
#
class fuel_project::roles::storage {
  class { '::fuel_project::common' :}
  class { '::fuel_project::mirror' :}
}
