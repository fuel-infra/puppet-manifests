# Class: fuel_project::jenkins::slave::infra

class fuel_project::jenkins::slave::infra {
  $packages = [
    'bind9utils',
  ]

  ensure_packages($packages)
}
