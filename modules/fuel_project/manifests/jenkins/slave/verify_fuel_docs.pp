# Class: fuel_project::jenkins::slave::verify_fuel_docs
#
# Class sets up verify_fuel_docs role
#
class fuel_project::jenkins::slave::verify_fuel_docs {
  $packages = [
    'inkscape',
    'make',
    'plantuml',
    'python-cloud-sptheme',
    'python-sphinx',
    'python-sphinxcontrib.plantuml',
    'rst2pdf',
    'texlive-font-utils',
  ]

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'libjpeg-dev',
      ]
    }
    'RedHat': {
      $additional_packages = [
        'libjpeg-turbo-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }

  ensure_packages(concat($packages, $additional_packages))
}
