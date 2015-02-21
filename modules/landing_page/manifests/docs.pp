# Class: landing_page::docs
#
class landing_page::docs (
  $apply_firewall_rules   = false,
  $firewall_allow_sources = {},
  $package                = 'landing-page-docs',
  $nginx_server_name      = $::fqdn,
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = 'proxy',
  $nginx_www_root         = '/var/www/docs_landing',
) {
  package { $package :
    ensure => 'present',
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'docs_landing' :
    server_name => [$nginx_server_name],
    listen_port => 80,
    www_root    => $nginx_www_root,
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => [80, 443],
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
