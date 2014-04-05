class build_fuel_iso {
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages

  package { $packages :
    ensure => installed,
  }
}
