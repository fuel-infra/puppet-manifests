# Class: fuel_project::mongo::server
#
# MongoDB server setup module
# Used as wrapper for puppetlabs-mongodb to setup replicaset members from hiera
#
# Parameters:
#   [*replication_members*]       - Array: the list of replicaset members
#
# Requires:
#   - puppetlabs-mongodb
#
class fuel_project::mongo::server (
  $replication_members = [],
) {
  mongodb_replset { 'rsmain' :
    ensure  => 'present',
    members => $replication_members,
  }
}
