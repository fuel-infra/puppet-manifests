# Class: fuel_project::glusterfs
#
# Parameters:
#  $create_pool:
#    if false, then it's just install glusterfs server and client
#  $gfs_pool:
#    list of nodes with glusterfs server installed, will be used for pool
#  $gfs_volume_name:
#    name of datapoint (shared point), will be used by clients for mounting,
#    example: mount -t glusterfs $gfs_pool[0]:/$gfs_volume_name /mnt/local
#  $gfs_brick_point:
#    mount points which are going to be used to building bricks
#
#  The above parameters in terms of glusterfs:
#  1. gluster peer probe $gfs_pool[0]
#     gluster peer probe $gfs_pool[1]
#  2. mkdir -p $gfs_brick_point
#     gluster volume create $gfs_volume_name replica 2 transport tcp \
#          $gfs_pool[0]:$gfs_brick_point $gfs_pool[1]:$gfs_brick_point force
#
#
class fuel_project::glusterfs (
  $apply_firewall_rules = false,
  $firewall_allow_sources = {},
  $create_pool = false,
  $gfs_pool = [ 'slave-13.test.local','slave-14.test.local' ],
  $gfs_volume_name = 'data',
  $gfs_brick_point = '/mnt/brick',

){
  class { '::fuel_project::common':
    external_host => $apply_firewall_rules,
  }

  class { '::glusterfs': }

  file { $gfs_brick_point:
    ensure  => directory,
    owner   => root,
    group   => root,
    recurse => true,
  }

  if $create_pool == true {
    glusterfs_pool { $gfs_pool: } ->
    glusterfs_vol { $gfs_volume_name :
      replica => 2,
      brick   => [ "${gfs_pool[0]}:${gfs_brick_point}", "${gfs_pool[1]}:${gfs_brick_point}"],
      force   => true,
      require => File[$gfs_brick_point],
    }
  }

  if $apply_firewall_rules {
    include firewall_defaults::pre
    # 111   - RPC incomming
    # 24007 - Gluster Daemon
    # 24008 - Management
    # 49152 - (GlusterFS versions 3.4 and later) - Each brick for every volume on your host requires it's own port.
    #         For every new brick, one new port will be used.
    # 2049, 38465-38469 - this is required by the Gluster NFS service.
    create_resources(firewall, $firewall_allow_sources, {
      ensure  => present,
      dport    => [111, 24007, 24008, 49152, 2049, 38465, 38466, 38467, 38468, 38469],
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }

}
