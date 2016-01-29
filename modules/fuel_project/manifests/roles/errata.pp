# Class: fuel_project::roles::errata
#
# This class deploys errata role.
#
class fuel_project::roles::errata {
  class { '::fuel_project::roles::errata::web' :}
  class { '::fuel_project::roles::errata::database' :}
}
