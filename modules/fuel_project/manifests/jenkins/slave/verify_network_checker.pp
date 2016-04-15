# Class: fuel_project::jenkins::slave::verify_network_checker
#
# Class sets up verify_network_checker role
#
class fuel_project::jenkins::slave::verify_network_checker {
  $packages = [
    'python-tox',
    'python-virtualenv',

  ]

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'libpcap-dev',
        'python-all-dev',
        'python2.6',
        'python2.6-dev',
        'python3-dev',
      ]
    }
    'RedHat': {
      $additional_packages = [
        'libpcap-devel',
        'python-devel',
        'python26',
        'python26-devel',
        'python3-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }
  ensure_packages(concat($packages, $additional_packages))
}
