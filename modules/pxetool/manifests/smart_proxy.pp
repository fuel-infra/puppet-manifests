# Class: pxetool::smart_proxy
#
# This class installs Trivial File Transfer Protocol Server package, syslinux
# package and then copies required pxelinux.0 file to tftp directory.
#
class pxetool::smart_proxy {
  $packages = [
    'syslinux-common',
    'tftpd-hpa',
  ]

  ensure_packages($packages)

  file { '/var/lib/tftpboot/pxelinux.0':
    ensure  => 'present',
    source  => '/usr/lib/syslinux/pxelinux.0',
    require => Package[$packages],
  }
}
