class build_fuel_iso {
  include dpkg
  include virtual::packages
  include virtual::repos
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages

  realize Apt::Source['docker']
  realize Package[$packages]

  exec { "install-grunt-cli":
    command => '/usr/bin/npm install -g grunt-cli',
    logoutput => on_failure,
  }

  Class['dpkg']->
    Apt::Source['docker']->
    Package[$packages]->
    Exec['install-grunt-cli']
}
