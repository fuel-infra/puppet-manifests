# Class: fuel_project::web
#
# This class deploys Nginx websites.
#
# Parameters:
#   [*fuel_landing_page*] - deploy fuel landing page
#   [*docs_landing_page*] - deploy docs landing page
#
class fuel_project::web (
  $fuel_landing_page = false,
  $docs_landing_page = false,
) {
  class { '::fuel_project::nginx' :}
  class { '::fuel_project::common' :}

  if ($fuel_landing_page) {
    class { '::landing_page' :}
  }

  if ($docs_landing_page) {
    class { '::landing_page::docs' :}
  }
}
