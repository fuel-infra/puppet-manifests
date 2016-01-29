# Class: fuel_project::tpi::puppetmaster
#
# Used for deployment of TPI puppet master
#
# Parameters:
#   [*local_home_basenames*] - TPI NFS shares basenames
#
class fuel_project::tpi::puppetmaster (
  $local_home_basenames= [],
) {

  class { 'tpi::nfs_client' :
    local_home_basenames => $local_home_basenames,
  }

  class { '::fuel_project::puppet::master' : }

}
