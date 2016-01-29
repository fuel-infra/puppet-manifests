# Class: fuel_project::jenkins::slave::infra
#
# This class deploys infra specific slave customizations.
#
class fuel_project::jenkins::slave::infra {
  $packages = [
    'bind9utils',
  ]

  ensure_packages($packages)
}
