#Class fuel_project::devops_tools
#
class fuel_project::devops_tools {
  class { '::fuel_project::common' :}
  class { '::fuel_project::devops_tools::lpbugmanage' :}
  class { '::fuel_project::devops_tools::lpupdatebug' :}
}
