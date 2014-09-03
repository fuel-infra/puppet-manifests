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
    'build-essential',
    'coreutils',
    'createrepo',
    'debootstrap',
    'extlinux',
    'genisoimage',
    'git',
    'gitweb',
    'ipmitool',
    'isomd5sum',
    'kpartx',
    'libconfig-auto-perl',
    'libffi-dev',
    'libmysqlclient-dev',
    'libparse-debian-packages-perl',
    'lrzip',
    'nfs-kernel-server',
    'php5',
    'php5-fpm',
    'php5-mysql',
    'postgresql-server-dev-all',
    'python-daemon',
    'python-dev',
    'python-django-pxetool',
    'python-jinja2',
    'python-netaddr',
    'python-nose',
    'python-pip',
    'python-setuptools',
    'python-virtualenv',
    'realpath',
    'ruby-builder',
    'ruby-bundler',
    'ruby-dev',
    'rubygems-integration',
    'syslinux',
    'tzdata',
    'unzip',
    'vlan',
    'yum',
    'yum-utils',
  ]

  @package {$packages :}
  # /Package list

}
