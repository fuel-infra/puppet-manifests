# Definition: tpi::localhome
#
# This defines local home that should remain visible on top of autofs.
#
# Parameters:
#   [*local_home_base*] - path to home base
#
define tpi::localhome($local_home_base='/usr/local/home') {

  validate_string($local_home_base, $name)
  validate_absolute_path("${local_home_base}/${name}")

  file { "${local_home_base}/${name}":
    ensure => 'directory',
    mode   => '0755',
    owner  => $name,
    group  => $name,
  }

  mount { "${local_home_base}/${name}":
    ensure  => 'mounted',
    device  => "/home/${name}",
    fstype  => 'none',
    options => 'rw,bind',
    atboot  => true,
    require => File["${local_home_base}/${name}"],
  }

}
