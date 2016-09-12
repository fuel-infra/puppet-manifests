# Class: fuel_project::roles::perestroika::builder
#
# This class deploys Jenkins slave host for building packages.
#
# Parameters:
#   [*packages*] - packages required for builder
#

class fuel_project::roles::perestroika::builder (
  $packages     = [
    'createrepo',
    'devscripts',
    'git',
    'python-setuptools',
    'reprepro',
    'yum-utils',
  ],
){

  # install required packages
  ensure_packages($packages)

}
