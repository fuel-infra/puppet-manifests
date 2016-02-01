# Class: transmission::daemon
#
# This class deploys Transmission daemon and configures it.
#
# Parameters:
#   [*alt_speed_down*] - alternative download speed
#   [*alt_speed_enabled*] - alternative speed limits enabled
#   [*alt_speed_time_begin*] - alternative speed limits start time
#   [*alt_speed_time_day*] - alternative speed limits days
#   [*alt_speed_time_enabled*] - alternative speed limit time trigger
#   [*alt_speed_time_end*] - alternative speed limits end time
#   [*alt_speed_up*] - alternative upload speed
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*bind_address_ipv4*] - ipv4 listening address
#   [*bind_address_ipv6*] - ipv6 listening address
#   [*blocklist_enabled*] - enable blocklist
#   [*blocklist_url*] - blocklist url
#   [*cache_size_mb*] - cache size used by Transmission
#   [*dht_enabled*] - enable DHT services
#   [*download_dir*] - download directory path
#   [*download_limit*] - download speed limit
#   [*download_limit_enabled*] - enable download limit
#   [*download_queue_enabled*] - enable dowload queue
#   [*download_queue_size*] - download queue size
#   [*encryption*] - connection encryption:
#     0 = Prefer unencrypted connections,
#     1 = Prefer encrypted connections,
#     2 = Require encrypted connections
#   [*idle_seeding_limit*] - stop seeding after being idle for N minutes
#   [*idle_seeding_limit_enabled*] - enable seeding limit
#   [*incomplete_dir*] - incomplete torrents storage path
#   [*incomplete_dir_enabled*] - use incomplete storage
#   [*lpd_enabled*] - enable local peer discovery
#   [*max_peers_global*] - maximum peers global limit
#   [*message_level*] - set verbosity of transmission messages:
#     0 = None, 1 = Error, 2 = Info, 3 = Debug
#   [*peer_congestion_algorithm*] - http://www.pps.jussieu.fr/~jch/software/bittorrent/tcp-congestion-control.html
#   [*peer_limit_global*] - maximum peers global limit
#   [*peer_limit_per_torrent*] - maximum peers per torrent
#   [*peer_port*] - peer connection port (static)
#   [*peer_port_random_high*] - highest limit of randomized port
#   [*peer_port_random_low*] - lowest limit of randomized port
#   [*peer_port_random_on_start*] - use randomized peer port
#   [*peer_socket_tos*] - set the Type-Of-Service (TOS) parameter for outgoing
#     TCP packets, possible values are "default", "lowcost", "throughput",
#     "lowdelay" and "reliability".
#   [*pex_enabled*] - enable Peer Exchange (PEX)
#   [*port_forwarding_enabled*] - enable UPnP or NAT-PMP
#   [*preallocation*] - file preallocation type: 0 = Off, 1 = Fast, 2 = Full
#   [*prefetch_enabled*] - Transmission will hint to the OS which piece data
#     it's about to read from disk in order to satisfy requests from peers
#   [*queue_stalled_enabled*] - torrents that have not shared data for
#     queue-stalled-minutes are treated as 'stalled' and are not counted
#     against the queue-download-size and seed-queue-size limits
#   [*queue_stalled_minutes*] - see queue_stalled_enabled
#   [*ratio_limit*] - ratio limit to stop seeding after reaching it
#   [*ratio_limit_enabled*] - enable ratio limit
#   [*rename_partial_files*] - partially downloaded files with ".part"
#   [*rpc_authentication_required*] - enable authentication for RPC
#   [*rpc_bind_address*] - RPC listening address
#   [*rpc_enabled*] - enable RPC connections
#   [*rpc_password*] - RPC password
#   [*rpc_port*] - RPC port
#   [*rpc_url*] - RPC url (default: /transmission)
#   [*rpc_username*] - RPC user name
#   [*rpc_whitelist*] - RPC whitelisted hosts
#   [*rpc_whitelist_enabled*] - enable RPC whitelist
#   [*scrape_paused_torrents_enabled*] - scrape paused torrents
#   [*script_torrent_done_enabled*] - run script when download is finished
#   [*script_torrent_done_filename*] - script to run when download is finished
#   [*seed_queue_enabled*] - enable seed queue
#   [*seed_queue_size*] - seed queue size
#   [*speed_limit_down*] - download speed limit
#   [*speed_limit_down_enabled*] - enable download speed limit
#   [*speed_limit_up*] - upload speed limit
#   [*speed_limit_up_enabled*] - enable upload speed limit
#   [*start_added_torrents*] - automatically start dowloading new torrents
#   [*trash_original_torrent_files*] - delete torrents added from the watch
#     directory
#   [*umask*] - umask variable for new files
#   [*upload_limit*] - upload speed limit
#   [*upload_limit_enabled*] - enable upload speed limit
#   [*upload_slots_per_torrent*] - maximum upload seeds per torrent
#   [*utp_enabled*] - enable Micro Transport Protocol (uTP)
#
class transmission::daemon (
  $alt_speed_down                 = 0,
  $alt_speed_enabled              = false,
  $alt_speed_time_begin           = 540,
  $alt_speed_time_day             = 1024000,
  $alt_speed_time_enabled         = false,
  $alt_speed_time_end             = 1024000,
  $alt_speed_up                   = 0,
  $apply_firewall_rules           = false,
  $bind_address_ipv4              = '0.0.0.0',
  $bind_address_ipv6              = '::',
  $blocklist_enabled              = false,
  $blocklist_url                  = 'http://www.example.com/blocklist',
  $cache_size_mb                  = 4,
  $dht_enabled                    = true,
  $download_dir                   = '/srv/downloads',
  $download_limit                 = 1024000,
  $download_limit_enabled         = false,
  $download_queue_enabled         = false,
  $download_queue_size            = 10,
  $encryption                     = true,
  $idle_seeding_limit             = 720,
  $idle_seeding_limit_enabled     = false,
  $incomplete_dir                 = '/srv/downloads/.incomplete',
  $incomplete_dir_enabled         = false,
  $lpd_enabled                    = true,
  $max_peers_global               = 200,
  $message_level                  = 3,
  $peer_congestion_algorithm      = 'cubic',
  $peer_limit_global              = 240,
  $peer_limit_per_torrent         = 60,
  $peer_port                      = 55589,
  $peer_port_random_high          = 49573,
  $peer_port_random_low           = 49152,
  $peer_port_random_on_start      = false,
  $peer_socket_tos                = 'default',
  $pex_enabled                    = true,
  $port_forwarding_enabled        = false,
  $preallocation                  = true,
  $prefetch_enabled               = true,
  $queue_stalled_enabled          = false,
  $queue_stalled_minutes          = 30,
  $ratio_limit                    = 2,
  $ratio_limit_enabled            = false,
  $rename_partial_files           = true,
  $rpc_authentication_required    = true,
  $rpc_bind_address               = '0.0.0.0',
  $rpc_enabled                    = true,
  $rpc_password                   = '{6ad470ec62b0511b63340dca2950d750181598efnHKvN1ge',
  $rpc_port                       = 9091,
  $rpc_url                        = '/transmission/',
  $rpc_username                   = 'transmission',
  $rpc_whitelist                  = '127.0.0.1',
  $rpc_whitelist_enabled          = false,
  $scrape_paused_torrents_enabled = true,
  $script_torrent_done_enabled    = false,
  $script_torrent_done_filename   = '',
  $seed_queue_enabled             = false,
  $seed_queue_size                = 10,
  $speed_limit_down               = 1240000,
  $speed_limit_down_enabled       = false,
  $speed_limit_up                 = 1650065,
  $speed_limit_up_enabled         = false,
  $start_added_torrents           = true,
  $trash_original_torrent_files   = false,
  $umask                          = 18,
  $upload_limit                   = 100,
  $upload_limit_enabled           = 0,
  $upload_slots_per_torrent       = 14,
  $utp_enabled                    = true,
) {
  include transmission::params

  $config = $transmission::params::config
  $packages = $transmission::params::packages
  $service = $transmission::params::service

  package { $packages :
    ensure        => 'present',
  }

  file { "${config}-new" :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('transmission/settings.json.erb'),
  }

  if $apply_firewall_rules {
    Class['firewall_defaults::pre']->
    firewall { '1000 allow transmission TCP peer connections' :
      port   => 55589,
      proto  => 'tcp',
      action => 'accept',
    }->
    firewall { '1000 allow transmission UDP peer connections' :
      port   => 55589,
      proto  => 'udp',
      action => 'accept',
    }->
    firewall { '1000 allow transmission multicast connections' :
      port   => 6771,
      proto  => 'udp',
      action => 'accept',
    }
  }

  case $::osfamily {
    'Debian': {
      $transmission_user = 'debian-transmission'
    }
    'RedHat': {
      $transmission_user = 'transmission'
    }
    default: { }
  }

  file { $download_dir :
    ensure => 'directory',
    owner  => $transmission_user,
    group  => $transmission_user,
  }

  exec { "${service}-reload" :
    command     => "service ${service} stop ; \
      cp ${config}-new ${config} ; \
      service ${service} start",
    refreshonly => true,
    logoutput   => on_failure,
  }


  Package[$packages]->
    File["${config}-new"]->
    File[$download_dir]~>
    Exec["${service}-reload"]

  File["${config}-new"]~>
    Exec["${service}-reload"]
}
