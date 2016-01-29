# Class: fuel_project::roles::errata::web
#
# This class deploys web frontend part for Errata.
#
class fuel_project::roles::errata::web {
  if (!defined(Class['::fuel_project::common'])) {
    class { '::fuel_project::common' :}
  }
  class { '::fuel_project::nginx' :}
  class { '::errata::web' :}
}
