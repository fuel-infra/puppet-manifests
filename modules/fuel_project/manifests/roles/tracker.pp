# Class: fuel_project::roles::tracker
#
# This class deploys Opentracker role.
#
class fuel_project::roles::tracker {
  class { '::fuel_project::common' :}
  class { '::opentracker' :}
}
