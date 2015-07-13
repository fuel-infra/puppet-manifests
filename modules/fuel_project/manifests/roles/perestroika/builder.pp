# Class: fuel_project::roles::perestroika::builder
#
# jenkins slave host for building packages
# see hiera file for list and params of used classes

class fuel_project::roles::perestroika::builder (
  $packages = [
    'createrepo',
    'devscripts',
    'git',
    'python-setuptools',
    'reprepro',
    'yum-utils',
  ],
) {

  # install packages
  ensure_packages($packages)
}
