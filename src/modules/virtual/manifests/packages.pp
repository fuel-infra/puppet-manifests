# Class: virtual::packages
#
class virtual::packages {
  # Package list

  Package {
    ensure => 'present',
  }

  # Howto sort packages:
  # sed -n '/\$packages = \[/,/\]/{/\$packages/d;/\]/d;p}' modules/virtual/manifests/packages.pp | sort
  $packages = [
    'coreutils',
    'gitweb',
    'ipmitool',
    'libffi-dev',
    'nfs-kernel-server',
    'postgresql-server-dev-all',
    'python-dev',
    'python-django-pxetool',
    'python-netaddr',
    'python-virtualenv',
    'syslinux',
    'tzdata',
    'vlan',
  ]

  @package {$packages :}
  # /Package list

}
