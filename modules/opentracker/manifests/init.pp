# Class: opentracker
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
