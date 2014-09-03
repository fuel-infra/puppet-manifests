# Class: fuel_project::puppet::master
#
class fuel_project::puppet::master (
  $apply_firewall_rules = false,
  $external_host = false,
  $firewall_allow_sources = [],
  $hiera_backends = ['yaml'],
  $hiera_config = '/etc/hiera.yaml',
  $hiera_config_template = 'puppet/hiera.yaml.erb',
  $hiera_hierarchy = ['nodes/%{::clientcert}', 'roles/%{::role}', 'common'],
  $hiera_json_datadir = '/var/lib/hiera',
  $hiera_logger = 'console',
  $hiera_merge_behavior = 'deeper',
  $hiera_yaml_datadir = '/var/lib/hiera',
  $puppet_config = '/etc/puppet/puppet.conf',
  $puppet_config_template = 'puppet/puppet.conf.erb',
  $puppet_environment = 'production',
  $puppet_server = '',
) {
  class { '::fuel_project::common' :
    external_host => $external_host,
  }->
  class { '::puppet::master' :
    apply_firewall_rules   => $external_host,
    firewall_allow_sources => $firewall_allow_sources,
    hiera_backends         => $hiera_backends,
    hiera_config           => $hiera_config,
    hiera_config_template  => $hiera_config_template,
    hiera_hierarchy        => $hiera_hierarchy,
    hiera_json_datadir     => $hiera_json_datadir,
    hiera_logger           => $hiera_logger,
    hiera_merge_behavior   => $hiera_merge_behavior,
    hiera_yaml_datadir     => $hiera_yaml_datadir,
    puppet_config          => $puppet_config,
    puppet_config_template => $puppet_config_template,
    puppet_environment     => $puppet_environment,
    puppet_server          => $puppet['master'],
  }
}
