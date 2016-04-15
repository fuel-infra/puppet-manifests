#
# Class: fuel_project::jenkins::slave::package_build
#
# Class describes configuration for Fuel ISO build node
#
# Parameters:
#   [*packages*] Array, List of packages to install
#   [*pins*] Hash, Hash to be passed to create_resources with pins in the form
#     of:
#     $pins = {
#       'package' => {
#         'version': 1.0
#       }
#     }
#
class fuel_project::jenkins::slave::package_build {
  include ::docker
  include ::fuel_project::nginx

  $packages = [
    'devscripts',
    'libparse-debcontrol-perl',
    'make',
    'mock',
    'npm',
    'nodejs=0.10.25~dfsg2-2ubuntu1',
    'nodejs-legacy=0.10.25~dfsg2-2ubuntu1',
    'pigz',
    'lzop',
    'python-setuptools',
    'python-rpm',
    'python-pbr',
    'reprepro',
    'ruby',
    'sbuild',
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
