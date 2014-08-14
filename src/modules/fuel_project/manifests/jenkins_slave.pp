class fuel_project::jenkins_slave (
  $external_host  = true,
  $build_fuel_iso = false,
  $run_tests      = true,
) {
  include virtual::packages

  include common
  if $run_tests == true {
    class { '::libvirt' :
      listen_tls => false,
      listen_tcp => true,
      auth_tcp => 'none',
      mdns_adv => false,
      unix_sock_group => 'libvirtd',
      unix_sock_rw_perms => '0777',
      python => true,
      qemu => true,
      deb_default => {
        'libvirtd_opts' => '-d -l',
      }
    }

    libvirt_pool { 'default' :
      ensure     => 'present',
      type       => 'dir',
      autostart  => true,
      target     => '/var/lib/libvirt/images',
      require    => Class['libvirt'],
    }

    include venv
    include system_tests
    include transmission_daemon
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
