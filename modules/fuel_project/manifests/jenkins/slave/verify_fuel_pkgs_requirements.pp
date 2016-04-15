# Class: fuel_project::jenkins::slave::verify_fuel_pkgs_requirements
#
# Class sets up verify_fuel_pkgs_requirements role
#
class fuel_project::jenkins::slave::verify_fuel_pkgs_requirements {
  $packages = [
    'devscripts',
    'yum-utils',
  ]

  ensure_packages($packages)
}
