# Class: fuel_project::jenkins::slave::run_k8s
#
# Class sets up run_k8s role
#
class fuel_project::jenkins::slave::run_k8s {
  case $::osfamily {
    'Debian': {
      $packages = [
        'ansible',
        'git',
        'python-netaddr',
        'software-properties-common',
        'sshpass',
      ]
    }
    default: {
      $packages = []
    }
  }

  ensure_packages($packages)
}
