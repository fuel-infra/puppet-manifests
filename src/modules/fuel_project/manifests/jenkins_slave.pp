class fuel_project::jenkins_slave (
  $external_host  = true,
  $build_fuel_iso = false,
  $run_tests      = true,
) {
  include virtual::packages

  include common
  if $run_tests == true {
    class { 'libvirt' :
      define_storage => true,
      external_host  => $external_host,
    }
    include venv
    include postgresql
    include system_tests
    include transmission_daemon
    realize Package ['qemu-kvm']
  }

  if $external_host == true {
    include jenkins::slave
  } else {
    include jenkins::swarm_slave
  }

  if $build_iso == true {
    class { '::build_fuel_iso' :
      external_host => $external_host,
    }
  }
}
