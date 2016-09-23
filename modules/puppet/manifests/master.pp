# Class: puppet::master
#
# This class deploys Puppet masters instance.
#
# Parameters are mostly described in 'params.pp' file. Some additional ones:
#   [*nginx_access_log*] - access log file path
#   [*nginx_error_log*] - error log file path
#   [*nginx_log_format*] - log format
#   [*puppet_master_run_with*] - 'webrick' or 'nginx+uwsgi'
#
class puppet::master (
  $autosign               = $::puppet::params::autosign,
  $config                 = $::puppet::params::config,
  $config_template        = $::puppet::params::master_config_template,
  $environment            = $::puppet::params::environment,
  $firewall_allow_sources = $::puppet::params::firewall_allow_sources,
  $hiera_config           = $::puppet::params::hiera_config,
  $hiera                  = $::puppet::params::hiera,
  $nginx_access_log       = '/var/log/nginx/access.log',
  $nginx_error_log        = '/var/log/nginx/error.log',
  $nginx_log_format       = undef,
  $packages               = $::puppet::params::master_packages,
  $puppet_master_run_with = $::puppet::params::master_run_with,
  $report                 = $::puppet::params::report,
  $service                = $::puppet::params::master_service,
) inherits ::puppet::params {
  puppet::config { 'master-config' :
    config          => $config,
    config_template => $config_template,
    environment     => $environment,
    report          => $report,
  }

  ensure_packages($packages)

  if ($hiera['merge_behavior'] == 'deeper') {
    package { 'deep_merge' :
      ensure   => 'present',
      provider => 'gem',
    }
  }

  if (has_key($hiera, 'eyaml')) {
    package { 'hiera-eyaml' :
      ensure   => 'present',
      provider => 'gem',
    }
  }

  if ($puppet_master_run_with == 'webrick') {
    service { $service :
      ensure     => 'running',
      enable     => true,
      hasstatus  => true,
      hasrestart => false,
      require    => [
        Package[$packages],
        Puppet::Config['master-config'],
      ]
    }
  }
  elsif ($puppet_master_run_with == 'nginx+uwsgi') {
    service { $service :
      ensure  => 'stopped',
      enable  => false,
      require => Package[$packages],
      notify  => Service[nginx]
    }
    if (!defined(Class['uwsgi'])) {
      class { 'uwsgi' :}
    }

    file { '/etc/puppet/rack' :
      ensure => 'directory',
    }

    file { '/etc/puppet/rack/config.ru' :
      ensure  => 'present',
      owner   => 'puppet',
      group   => 'puppet',
      mode    => '0644',
      content => template('puppet/config.ru.erb'),
      require => File['/etc/puppet/rack'],
      before  => Class['uwsgi'],
    }

    uwsgi::application { 'puppetmaster' :
      plugins   => 'rack',
      rack      => '/etc/puppet/rack/config.ru',
      chdir     => '/etc/puppet/rack',
      env       => 'HOME=/var/lib/puppet',
      uid       => 'puppet',
      gid       => 'puppet',
      socket    => '127.0.0.1:8141',
      subscribe => [
        File['/etc/puppet/rack/config.ru'],
        File[$hiera_config],
        Puppet::Config['master-config'],
      ],
    }

    if (!defined(Class['nginx'])) {
      class { '::nginx' :}
    }
    ::nginx::resource::vhost { 'puppetmaster' :
      ensure                 => 'present',
      listen_port            => 8140,
      ssl_port               => 8140,
      server_name            => [$::fqdn],
      ssl                    => true,
      ssl_cert               => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
      ssl_key                => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
      ssl_crl                => '/var/lib/puppet/ssl/crl.pem',
      ssl_client_certificate => '/var/lib/puppet/ssl/certs/ca.pem',
      ssl_verify_client      => 'optional',
      access_log             => $nginx_access_log,
      error_log              => $nginx_error_log,
      format_log             => $nginx_log_format,
      uwsgi                  => '127.0.0.1:8141',
      location_cfg_append    => {
        uwsgi_connect_timeout => '3m',
        uwsgi_read_timeout    => '3m',
        uwsgi_send_timeout    => '3m',
        uwsgi_modifier1       => 7,
        uwsgi_param           => {
          'SSL_CLIENT_S_DN'   => '$ssl_client_s_dn',
          'SSL_CLIENT_VERIFY' => '$ssl_client_verify',
        },
      }
    }
  } else {
    fail "Unknown value for puppet_master_run_with parameter: ${puppet_master_run_with}"
  }

  file { $hiera_config :
    ensure  => 'present',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0400',
    content => inline_template("<%= require 'yaml' ; YAML.dump(@hiera) %>"),
    require => Package[$packages]
  }

  class { 'puppet::auth' :}
}
