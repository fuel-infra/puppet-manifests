# Class: fuel_project::devops_tools
#
# This class deploys particular devops tools on host.
#
# Parameters:
#   [*lpbugmanage*] - install lpbugmanage tool
#   [*lpupdatebug*] - install lpupdatebug tool
#
class fuel_project::devops_tools (
  $lpbugmanage = false,
  $lpupdatebug = false,
) {

  class { '::fuel_project::common' :}

  if($lpbugmanage) {
    class { '::fuel_project::devops_tools::lpbugmanage' :}
  }

  if($lpupdatebug) {
    class { '::fuel_project::devops_tools::lpupdatebug' :}
  }
}
