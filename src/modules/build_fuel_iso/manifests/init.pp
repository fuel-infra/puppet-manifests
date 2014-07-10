class build_fuel_iso {
  include dpkg
  include virtual::packages
  include virtual::repos
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages

  realize Virtual::Repos::Repository['docker']
  realize Package[$packages]

  exec { "install-grunt-cli":
    command => '/usr/bin/npm install -g grunt-cli',
    logoutput => on_failure,
  }

  Class['dpkg']->
    Package[$packages]->
    Exec['install-grunt-cli']
}
