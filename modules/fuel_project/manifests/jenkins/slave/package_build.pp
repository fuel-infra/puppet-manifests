# Class: fuel_project::jenkins::slave::package_build
#
# Class describes configuration for package building.
#
class fuel_project::jenkins::slave::package_build {
  include ::docker
  include ::fuel_project::nginx

  $packages = [
    'createrepo',
    'devscripts',
    'git',
    'libparse-debcontrol-perl',
    'lzop',
    'make',
    'mock',
    'nodejs-legacy=0.10.25~dfsg2-2ubuntu1',
    'nodejs=0.10.25~dfsg2-2ubuntu1',
    'npm',
    'pigz',
    'python-pbr',
    'python-rpm',
    'python-setuptools',
    'reprepro',
    'ruby',
    'sbuild',
    'yum-utils',
  ]

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'zlib1g',
        'zlib1g-dev',
      ]
    }
    'RedHat': {
      $additional_packages = [
        'zlib',
        'zlib-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }

  ensure_packages(concat($packages, $additional_packages))

  User <| title == 'jenkins' |> {
    groups  +> 'mock',
      require => [
        Package[$packages],
      ]
  }

  ensure_resource('user', 'jenkins', {
    ensure => 'present'
  })
}
