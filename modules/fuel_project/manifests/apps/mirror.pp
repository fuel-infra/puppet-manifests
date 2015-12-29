# Class: fuel_project::apps::mirror
#
# This class deploys Nginx + Rsync powered storage with ability to upload files
# using rsync+ssh protocol.
#
# Parameters:
#   [*autoindex*] - directory autoindexing on http share
#   [*dir*] - storage path
#   [*firewall_allow_sources*] - unused variable
#   [*nginx_access_log*] - access log path
#   [*nginx_error_log*] - error log path
#   [*nginx_log_format*] - log format
#   [*port*] - http daemon listening port
#   [*rsync_mirror_lockfile*] - rsync lock_file for RO share
#   [*rsync_mirror_lockfile_rw*] - rsync lock_file for RW share
#   [*rsync_rw_share_comment*] - rsync RW share comment
#   [*rsync_share_comment*] - rsync RO share comment
#   [*rsync_writable_share*] - enable writable share
#   [*service_aliases*] - aliases for http service
#   [*service_fqdn*] - main FQDN for http service
#   [*sync_hosts_allow*] - hosts allowed to use RW legacy share
#   [*syncer_username*] - rsync+ssh protocol username for RW access
#   [*syncer_ssh_keys*] - rsync+ssh protocol keys for RW access
#
class fuel_project::apps::mirror (
  $autoindex                = 'on',
  $dir                      = '/var/www/mirror',
  $firewall_allow_sources   = {},
  $nginx_access_log         = '/var/log/nginx/access.log',
  $nginx_error_log          = '/var/log/nginx/error.log',
  $nginx_log_format         = 'proxy',
  $port                     = 80,
  $rsync_mirror_lockfile    = '/var/run/rsync_mirror.lock',
  $rsync_mirror_lockfile_rw = '/var/run/rsync_mirror_sync.lock',
  $rsync_rw_share_comment   = 'Fuel mirror sync',
  $rsync_share_comment      = 'Fuel mirror rsync share',
  $rsync_writable_share     = true,
  $service_aliases          = [],
  $service_fqdn             = "mirror.${::fqdn}",
  $sync_hosts_allow         = [],
  $syncer_username          = 'mirror-syncer',
  $syncer_ssh_keys          = {},
) {
  include rssh
  if(!defined(Class['rsync'])) {
    class { 'rsync' :
      package_ensure => 'present',
    }
  }

  file { $dir :
    ensure  => 'directory',
    owner   => $syncer_username,
    group   => $syncer_username,
    mode    => '0755',
    require => [
        Class['nginx'],
        User[$syncer_username],
      ],
  }

  if (!defined(Class['::rsync::server'])) {
    class { '::rsync::server' :
      gid        => 'root',
      uid        => 'root',
      use_chroot => 'yes',
      use_xinetd => false,
    }
  }

  ::rsync::server::module{ 'mirror':
    comment         => $rsync_share_comment,
    uid             => 'nobody',
    gid             => 'nogroup',
    list            => 'yes',
    lock_file       => $rsync_mirror_lockfile,
    max_connections => 100,
    path            => $dir,
    read_only       => 'yes',
    write_only      => 'no',
    require         => File[$dir],
  }

  # FIXME: It's legacy plain rsync share to be removed
  if ($rsync_writable_share) {
    ::rsync::server::module{ 'mirror-sync':
      comment         => $rsync_rw_share_comment,
      uid             => $syncer_username,
      gid             => $syncer_username,
      hosts_allow     => $sync_hosts_allow,
      hosts_deny      => ['*'],
      incoming_chmod  => '0755',
      outgoing_chmod  => '0644',
      list            => 'yes',
      lock_file       => $rsync_mirror_lockfile_rw,
      max_connections => 100,
      path            => $dir,
      read_only       => 'no',
      write_only      => 'no',
      require         => [
          File[$dir],
          User[$syncer_username],
        ],
    }
  }
  # /FIXME

  $syncer_homedir = "/var/lib/${syncer_username}"

  user { $syncer_username :
    ensure     => 'present',
    home       => $syncer_homedir,
    shell      => '/usr/bin/rssh',
    managehome => true,
    system     => true,
  }

  file { $syncer_homedir :
    ensure  => 'directory',
    owner   => $syncer_username,
    group   => $syncer_username,
    require => User[$syncer_username],
  }

  create_resources('ssh_authorized_key', $syncer_ssh_keys, {
    user    => $syncer_username,
    require => [
      User[$syncer_username],
      File[$plugins_dir],
      File[$syncer_homedir],
    ]})

  if (!defined(Class['::fuel_project::nginx'])) {
    class { '::fuel_project::nginx' :}
  }
  ::nginx::resource::vhost { 'mirror' :
    ensure              => 'present',
    www_root            => $dir,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    server_name         => [
      $service_fqdn,
      "mirror.${::fqdn}",
      join($service_aliases, ' ')
    ],
    location_cfg_append => {
      autoindex        => $autoindex,
      disable_symlinks => 'if_not_owner',
    },
  }
}
