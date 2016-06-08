# Class: fuel_project::jenkins::slave::infra
#
# This class deploys infra specific slave customizations.
#
class fuel_project::jenkins::slave::infra {
  $packages = [
    'bind9utils',
    'libffi-dev',
    'libldap2-dev',
    'libsasl2-dev',
    'libssl-dev',
  ]

  ensure_packages($packages)
}
