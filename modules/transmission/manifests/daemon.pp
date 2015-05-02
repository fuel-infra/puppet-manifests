# == Class: transmission::init
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

  file { $download_dir :
    ensure => 'directory',
    owner  => 'debian-transmission',
    group  => 'debian-transmission',
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
