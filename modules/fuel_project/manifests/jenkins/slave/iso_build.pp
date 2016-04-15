#
# Class: fuel_project::jenkins::slave::iso_build
#
# Class describes configuration for Fuel ISO build node
#
class fuel_project::jenkins::slave::iso_build {
  include ::docker
  include ::fuel_project::nginx
  include ::landing_page::updater

  $packages = [
    'bc',
    'build-essential',
    'createrepo',
    'debmirror',
    'debootstrap',
    'devscripts',
    'dosfstools',
    'genisoimage',
    'isomd5sum',
    'kpartx',
    'libparse-debcontrol-perl',
    'lrzip',
    'python-ipaddr',
    'python-jinja2',
    'python-nose',
    'python-paramiko',
    'python-virtualenv',
    'realpath',
    'reprepro',
    'rpm',
    'syslinux',
    'time',
    'unzip',
    'xorriso',
    'yum',
    'yum-utils',
  ]

  case $::osfamily {
    'Debian': {
      $deb_packages = [
        'extlinux',
        'libconfig-auto-perl',
        'libmysqlclient-dev',
        'libparse-debian-packages-perl',
        'libyaml-dev',
        'python-dev',
        'python-xmlbuilder',
        'ruby-bundler',
        'ruby-builder',
        'ruby-dev',
        'rubygems-integration',
      ]
      case $::lsbdistcodename {
        'trusty': {
          $additional_packages = concat($deb_packages, [
            'cpio',
            'python-lockfile=1:0.8-2ubuntu2',
            'python-daemon=1.5.5-1ubuntu1'])

          create_resources('apt::pin', {
            'cpio' => {
              'packages' => 'cpio',
              'version'  => '2.11+dfsg-1ubuntu1',
              'priority' => 1000,
            },
            'python-daemon' => {
              'packages' => 'python-daemon',
              'version'  => '1.5.5-1ubuntu1',
              'priority' => 1000,
            },
            'python-lockfile' => {
              'packages' => 'python-lockfile',
              'version'  => '1:0.8-2ubuntu2',
              'priority' => 1000,
            }
          })
        }
        'xenial': {
          $additional_packages = concat($deb_packages, [
            'cpio',
            'python-lockfile',
            'python-daemon'])
        }
        default: { }
      }
    }
    'RedHat': {
      $additional_packages = [
        'libyaml-devel',
        'python-daemon',
        'python-devel',
        'ruby-devel',
        'syslinux-extlinux',
      ]
    }
    default: {
      $additional_packages = []
    }
  }

  ensure_packages(
    concat($packages, $additional_packages),
    {require => Exec['apt_update']}
  )

  ensure_resource('group', 'mock', {
    ensure => 'present',
    system => true,
  })

  User <| title == 'jenkins' |> {
    groups  +> 'mock',
      require => [
        Package[$packages],
        Group['mock'],
      ]
  }

  ensure_resource('user', 'jenkins', {
    ensure => 'present'})

  ensure_resource('file', '/var/www', {
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  })

  ensure_resource('file', '/var/www/fuelweb-iso', {
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => [
      User['jenkins'],
      File['/var/www'],
    ],
  })

  ::nginx::resource::vhost { 'share':
    server_name => ['_'],
    autoindex   => 'on',
    www_root    => '/var/www',
    require     => [
      File['/var/www'],
    ],
  }
}
