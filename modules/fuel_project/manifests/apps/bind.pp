# Class: fuel_project::apps::bind
#
class fuel_project::apps::bind (
  $firewall_rules         = {
    '1000 - Allow DNS connections' => {
      source => '0.0.0.0/0',
      dports => [53],
      proto  => 'udp',
      action => 'accept',
    },
    '1000 - Allow DNS connections' => {
      source => '0.0.0.0/0',
      dports => [53],
      proto  => 'tcp',
      action => 'accept',
    },
  },
  $acls                   = {},
  $masters                = {},
  $listen_on_port         = '53',
  $listen_on_addr         = [ '127.0.0.1' ],
  $listen_on_v6_port      = '53',
  $listen_on_v6_addr      = [ '::1' ],
  $forwarders             = [],
  $directory              = '/var/named',
  $managed_keys_directory = undef,
  $hostname               = undef,
  $server_id              = undef,
  $version                = undef,
  $dump_file              = '/var/named/data/cache_dump.db',
  $statistics_file        = '/var/named/data/named_stats.txt',
  $memstatistics_file     = '/var/named/data/named_mem_stats.txt',
  $allow_query            = [ 'localhost' ],
  $allow_query_cache      = [],
  $recursion              = 'yes',
  $allow_recursion        = [],
  $allow_transfer         = [],
  $check_names            = [],
  $extra_options          = {},
  $dnssec_enable          = 'yes',
  $dnssec_validation      = 'yes',
  $dnssec_lookaside       = 'auto',
  $zones                  = {},
  $includes               = [],
  $views                  = {},
  $named_config           = '/etc/bind/named.conf',
) {
  class { '::bind' :}
  ::bind::server::conf { $named_config :
    acls                   => $acls,
    masters                => $masters,
    listen_on_port         => $listen_on_port,
    listen_on_addr         => $listen_on_addr,
    listen_on_v6_port      => $listen_on_v6_port,
    listen_on_v6_addr      => $listen_on_v6_addr,
    forwarders             => $forwarders,
    directory              => $directory,
    managed_keys_directory => $managed_keys_directory,
    hostname               => $hostname,
    server_id              => $server_id,
    version                => $version,
    dump_file              => $dump_file,
    statistics_file        => $statistics_file,
    memstatistics_file     => $memstatistics_file,
    allow_query            => $allow_query,
    allow_query_cache      => $allow_query_cache,
    recursion              => $recursion,
    allow_recursion        => $allow_recursion,
    allow_transfer         => $allow_transfer,
    check_names            => $check_names,
    extra_options          => $extra_options,
    dnssec_enable          => $dnssec_enable,
    dnssec_validation      => $dnssec_validation,
    dnssec_lookaside       => $dnssec_lookaside,
    zones                  => $zones,
    includes               => $includes,
    views                  => $views
  }

  if ($firewall_rules) {
    include firewall_defaults::pre
    ensure_resource('firewall', $firewall_rules, {})
  }
}
