class virtual::packages {
  # Package list

  Package {
    ensure => 'present',
  }

  $packages = [
    'atop',
    'bc',
    'build-essential',
    'coreutils',
    'createrepo',
    'curl',
    'debootstrap',
    'dstat',
    'extlinux',
    'genisoimage',
    'git',
    'gitweb',
    'htop',
    'isomd5sum',
    'kpartx',
    'libconfig-auto-perl',
    'libevent-dev',
    'libffi-dev',
    'libmysqlclient-dev',
    'libparse-debian-packages-perl',
    'lrzip',
    'nodejs',
    'nodejs-legacy',
    'npm',
    'php5',
    'php5-fpm',
    'php5-mysql',
    'postgresql-server-dev-all',
    'python-anyjson',
    'python-daemon',
    'python-dev',
    'python-devops',
    'python-django-pxetool',
    'python-glanceclient',
    'python-ipaddr',
    'python-jinja2',
    'python-keystoneclient',
    'python-nose',
    'python-novaclient',
    'python-paramiko',
    'python-pip',
    'python-proboscis',
    'python-seed-cleaner',
    'python-seed-client',
    'python-setuptools',
    'python-virtualenv',
    'python-xmlbuilder',
    'python-yaml',
    'puppet',
    'puppetmaster',
    'realpath',
    'ruby-builder',
    'ruby-bundler',
    'ruby-dev',
    'rubygems-integration',
    'sysstat',
    'tzdata',
    'unzip',
    'vncviewer',
    'yum',
    'yum-utils',
  ]

  @package {$packages :}

  @package {'lxc-docker-0.10.0' : ensure => '0.10.0' }
  @package {'multistrap' : ensure => '2.1.6ubuntu3' }
  # /Package list

  # Meta(pinnings, holds, etc.)
  # apt::hold supported in puppetlabs-apt >= 1.5:
  # apt::hold { 'multistrap': version => '2.1.6ubuntu3' }
  apt::pin { 'multistrap' :
    packages => 'multistrap',
    version => '2.1.6ubuntu3',
    priority => 1000,
  }
  # /Meta(pinnings, holds, etc.)
}
