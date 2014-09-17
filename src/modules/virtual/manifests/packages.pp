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
    'ipmitool',
    'nfs-kernel-server',
    'python-netaddr',
    'syslinux',
    'tzdata',
    'vlan',
  ]

  @package {$packages :}
  # /Package list

}
