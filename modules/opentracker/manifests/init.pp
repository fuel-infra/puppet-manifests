# Class: opentracker
#
# This class deploys opentracker instance.
#
# Parameters:
#   [*access_blacklist*] - access blacklist file location
#   [*access_stats*] - access stats host
#   [*access_stats_path*] - access stats URL
#   [*access_whitelist*] - access whitelist file location
#   [*batchsync_cluster_admin_ip*] - batchsync cluster admin IP
#   [*config*] - configuration file path
#   [*listen_tcp*] - listen on TCP port
#   [*listen_tcp_udp*] - listen on TCP and UDP ports
#   [*listen_udp*] - listen on UDP port
#   [*listen_udp_workers*] - workers ammount on UDP port
#   [*livesync_cluster_listen*] - livesync cluster listening host:port
#   [*livesync_cluster_node_ip*] - declares IPs for livesync cluster
#   [*packages*] - package name for opentracker
#   [*service*] - service name for opentracker
#   [*tracker_redirect_url*] - redirect GET / to specific URL
#   [*tracker_rootdir*] - chroot to specific directory
#   [*tracker_user*] - opentracker user to run with
#
class opentracker (
  $access_blacklist           = undef,
  $access_stats               = undef,
  $access_stats_path          = undef,
  $access_whitelist           = undef,
  $batchsync_cluster_admin_ip = undef,
  $config                     = '/etc/opentracker.conf',
  $listen_tcp                 = '0.0.0.0:8080',
  $listen_tcp_udp             = undef,
  $listen_udp                 = undef,
  $listen_udp_workers         = undef,
  $livesync_cluster_listen    = undef,
  $livesync_cluster_node_ip   = undef,
  $packages                   = ['opentracker'],
  $service                    = 'opentracker',
  $tracker_redirect_url       = undef,
  $tracker_rootdir            = '/var/lib/opentracker',
  $tracker_user               = 'opentracker',
) {
  ensure_packages($packages)

  user { $tracker_user :
    ensure     => 'present',
    home       => $tracker_rootdir,
    shell      => '/usr/sbin/nologin',
    system     => true,
    managehome => true,
  }

  file { $tracker_rootdir :
    ensure => 'present',
    owner  => $tracker_user,
  }

  file { $config :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('opentracker/opentracker.conf.erb'),
    require => Package[$packages],
    notify  => Service[$service],
  }

  service { $service :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => [
      File[$config],
      Package[$packages],
      File[$tracker_rootdir],
      User[$tracker_user],
    ],
  }
}
