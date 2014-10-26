# Class: puppet::master
#
class puppet::master (
  $apply_firewall_rules = $::puppet::params::apply_firewall_rules,
  $firewall_allow_sources = $::puppet::params::firewall_allow_sources,
  $hiera_backends = $::puppet::params::hiera_backends,
  $hiera_config = $::puppet::params::hiera_config,
  $hiera_config_template = $::puppet::params::hiera_config_template,
  $hiera_hierarchy = $::puppet::params::hiera_hierarchy,
  $hiera_json_datadir = $::puppet::params::hiera_json_datadir,
  $hiera_logger = $::puppet::params::hiera_logger,
  $hiera_merge_behavior = $::puppet::params::hiera_merge_behavior,
  $hiera_yaml_datadir = $::puppet::params::hiera_yaml_datadir,
  $autosign = $::puppet::params::autosign,
  $config = $::puppet::params::config,
  $config_template = $::puppet::params::master_config_template,
  $environment = $::puppet::params::environment,
  $package = $::puppet::params::master_package,
  $service = $::puppet::params::master_service,
  $server = '',
  $puppet_master_run_with = 'webrick', # or nginx+uwsgi
) inherits ::puppet::params {
  puppet::config { 'master-config' :
    hiera_backends        => $hiera_backends,
    hiera_config          => $hiera_config,
    hiera_config_template => $hiera_config_template,
    hiera_hierarchy       => $hiera_hierarchy,
    hiera_json_datadir    => $hiera_json_datadir,
    hiera_logger          => $hiera_logger,
    hiera_merge_behavior  => $hiera_merge_behavior,
    hiera_yaml_datadir    => $hiera_yaml_datadir,
    config                => $config,
    config_template       => $config_template,
    environment           => $environment,
  }

  if (!defined(Package[$package])) {
    package { $package :
      ensure => 'present',
    }
  }

  if ($hiera_merge_behavior == 'deeper') {
    package { 'deep_merge' :
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
        Package[$package],
        File[$puppet_config]
      ]
    }
  }
  elsif ($puppet_master_run_with == 'nginx+uwsgi') {
    service { $service :
      ensure => 'stopped',
      enable => false,
    }
    if (!defined(Class['uwsgi'])) {
      class { 'uwsgi' :}
    }

    if (!defined(Class['nginx'])) {
      class { 'nginx' :}
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
    }

    uwsgi::application { 'puppetmaster' :
      plugins => 'rack',
      rack    => '/etc/puppet/rack/config.ru',
      chdir   => '/etc/puppet/rack',
      env     => 'HOME=/var/lib/puppet',
      uid     => 'puppet',
      gid     => 'puppet',
      socket  => '127.0.0.1:8141',
    }

    file { '/etc/nginx/sites-available/puppetmaster.conf' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('puppet/nginx.conf.erb'),
      require => Class['nginx'],
    }

    file { '/etc/nginx/sites-enabled/puppetmaster.conf' :
      ensure  => 'link',
      target  => '/etc/nginx/sites-available/puppetmaster.conf',
      require => File['/etc/nginx/sites-available/puppetmaster.conf']
    }~>
    Service['nginx']
  } else {
    fail "Unknown value for puppet_master_run_with parameter: ${puppet_master_run_with}"
  }

  file { $hiera_config :
    ensure  => 'present',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0400',
    content => template($hiera_config_template),
    require => Package[$package]
  }

  if $apply_firewall_rules {
    include firewall_defaults::pre
    create_resources(firewall, $firewall_allow_sources, {
      dport   => '8140',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
