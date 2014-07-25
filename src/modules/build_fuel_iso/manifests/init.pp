class build_fuel_iso {
  include dpkg
  include virtual::packages
  include virtual::repos
  include build_fuel_iso::params

  $packages = $build_fuel_iso::params::packages

  realize Virtual::Repos::Repository['docker']
  realize Package[$packages]

  exec { 'install-grunt-cli' :
    command => '/usr/bin/npm install -g grunt-cli',
    logoutput => on_failure,
  }

  file { 'jenkins-sudo-for-build_iso' :
    path => '/etc/sudoers.d/build_fuel_iso',
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => template('build_fuel_iso/sudoers_d_build_fuel_iso.erb')
  }

  if $external_host {
    firewall { '010 accept all to docker0 interface':
      proto   => 'all',
      iniface => 'docker0',
      action  => 'accept',
      require => Package[$packages],
    }
  }

  Class['dpkg']->
    Package[$packages]->
    Exec['install-grunt-cli']->
    File['jenkins-sudo-for-build_iso']
}
