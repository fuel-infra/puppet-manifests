class build_fuel_iso {
  include packages
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages
  realize Package[$packages]

  exec { "install-grunt-cli":
    command => '/usr/bin/npm install -g grunt-cli',
    logoutput => on_failure,
  }
  Class['dpkg']->
    Package[$packages]->
    Exec['install-grunt-cli']
}
