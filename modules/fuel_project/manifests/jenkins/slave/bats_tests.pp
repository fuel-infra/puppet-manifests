# Class: fuel_project::jenkins::slave::bats_tests
#
# Class sets up bats_tests role
#
class fuel_project::jenkins::slave::bats_tests {
  $packages = [
    'bats',
    'xmlstarlet'
  ]

  ensure_packages($packages)
}
