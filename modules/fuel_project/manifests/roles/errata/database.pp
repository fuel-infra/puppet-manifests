# Class: fuel_project::roles::errata::database
#
# This class deploys database for errata role.
#
class fuel_project::roles::errata::database {
  if (!defined(Class['::fuel_project::common'])) {
    class { '::fuel_project::common' :}
  }
  class { '::errata::database' :}
}
