# Class: fuel_project::roles::blackduck::server::server
#
# This class is about configuration of Blackduck's server.
#
# Parameters:
#   [*blackduck_release*] - string, version of operation system
#   on a goal server.
#   [*database_path*] - string, directory where Blackduck's database
#   is placed. This variable is used to check that database exists.
#   [*iso*] - string, path to the image with Blackduck distro
#   [*mount_point*] - string, path to mount the iso
#   [*ssh_public_key*] - string, value of public ssh-key for an user
#   from Blackduck client
#
class fuel_project::roles::blackduck::server (
  $blackduck_release = 'Red Hat Enterprise Linux Server release 6.2 (Santiago)',
  $database_path     = '/var/lib/bds-export',
  $iso               = '/mnt/image.iso',
  $mount_point       = '/mnt/blackduck_distr',
  $ssh_public_key    = undef,
) {

  $dependencies = [
    'rsync',
    'rssh',
    'unzip',
  ]

  user { 'blackduck':
    ensure     => 'present',
    managehome => true,
    name       => 'blackduck',
    shell      => '/usr/bin/rssh',
  }

  class { 'rssh' :
    allow   => ['rsync'],
    users   => ['blackduck:022:10000:'],
    require => [
      User['blackduck'],
    ],
  }

  if ($ssh_public_key) {
    ssh_authorized_key { 'blackduck' :
      user    => 'blackduck',
      type    => 'ssh-rsa',
      key     => $ssh_public_key,
      require => [
        User['blackduck'],
      ]
    }
  }

  ensure_packages($dependencies)

  file { '/etc/blackduck-release':
    ensure  => 'present',
    content => $blackduck_release,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { $mount_point:
    ensure  => 'directory',
  }

  if ($iso) {
    mount { $mount_point:
      ensure  => 'mounted',
      name    => $mount_point,
      options => 'loop,ro',
      fstype  => 'iso9660',
      device  => $iso,
      require => [
        File[$mount_point],
      ]
    }

  }

  else {
    fail()
  }

  exec { 'install_server':
    command  => './install.sh -i silent',
    cwd      => $mount_point,
    provider => shell,
    timeout  => 600,
    returns  => [0, 255],
    unless   => 'bash -c "test -d /var/lib/bds-export"',
    onlyif   => [
      "test -f ${mount_point}/install.sh",
    ],
    require  => [
      Mount[$mount_point],
      Package[$dependencies],
    ]
  }

  service { 'bds-exportIP-postgresql':
    ensure   => 'running',
    enable   => true,
    provider => 'base',
    require  => [
      Exec['install_server'],
    ],
    start    => '/etc/init.d/bds-exportIP-postgresql start',
    status   => '/etc/init.d/bds-exportIP-postgresql status',
    stop     => '/etc/init.d/bds-exportIP-postgresql stop',
  }

  service { 'bds-exportIP-tomcat':
    ensure   => 'running',
    enable   => true,
    provider => 'base',
    require  => [
      Exec['install_server'],
      Service['bds-exportIP-postgresql'],
    ],
    start    => '/etc/init.d/bds-exportIP-tomcat start',
    status   => '/etc/init.d/bds-exportIP-tomcat status',
    stop     => '/etc/init.d/bds-exportIP-tomcat stop',
  }
}
