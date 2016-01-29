# Class: fuel_project::roles::perestroika::builder
#
# This class deploys Jenkins slave host for building packages.
#
# Parameters:
#   [*docker_package*] - docker package name
#   [*builder_user*] - builder user
#   [*known_hosts*] - known_host file entries
#   [*packages*] - packages required for builder
#

class fuel_project::roles::perestroika::builder (
  $docker_package,
  $builder_user = 'jenkins',
  $known_hosts  = undef,
  $packages     = [
    'createrepo',
    'devscripts',
    'git',
    'python-setuptools',
    'reprepro',
    'yum-utils',
  ],
){

  # ensure build user exists
  ensure_resource('user', $builder_user, {
    'ensure' => 'present'
  })

  # install required packages
  ensure_packages($packages)
  ensure_packages($docker_package)

  # ensure $builder_user in docker group
  # docker group will be created by docker package
  User <| title == $builder_user |> {
    groups  +> 'docker',
    require => Package[$docker_package],
  }

  if ($known_hosts) {
    create_resources('ssh::known_host', $known_hosts, {
      user      => $builder_user,
      overwrite => false,
      require   => User[$builder_user],
    })
  }

}
