# Class: fuel_project::jenkins::slave::kolla_build_tests
#
# Class sets up kolla_build_tests role
#
class fuel_project::jenkins::slave::kolla_build_tests {
  case $::osfamily {
    'Debian': {
      $packages = [
        'bridge-utils',
        'libxml2',
        'libxml2-dev',
        'libxslt1.1',
        'libxslt1-dev',
        'libyaml-dev',
        'lxc',
        'mariadb-client-core-5.5',
        'python-dev',
        'python-docker',
        'python-gdbm',
        'python-tox',
        'python3-dev',
        'sshpass',
        'vlan',
        'zlib1g-dev',
      ]
      package { 'ansible' :
        ensure => '1.9.5-1'
      }
      apt::pin { 'ansible' :
        packages => 'ansible',
        version  => '1.9.5-1',
        priority => 1000,
      }
    }
    'RedHat': {
      $packages = [
        'python-devel',
      ]
    }
    default: {
      $packages = []
    }
  }

  ensure_packages($packages)
}
