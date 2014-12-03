# Used for deployment of TPI lab
class fuel_project::tpi::lab (
) {

  class { '::fuel_project::jenkins::slave' :
    run_tests      => true,
  }

  # these packages will be installed from tpi apt repo defined in hiera
  $tpi_packages = [
    'linux-image-3.13.0-40-generic',
    'linux-headers-3.13.0-40-generic',
    'btsync',
  ]

  ensure_packages($tpi_packages)
}
