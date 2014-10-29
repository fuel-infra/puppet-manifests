# Class: fuel_project::puppet::master
#
class fuel_project::puppet::master (
  $apply_firewall_rules = false,
  $external_host = false,
  $firewall_allow_sources = {},
  $hiera_backends = ['yaml'],
  $hiera_config = '/etc/hiera.yaml',
  $hiera_config_template = 'puppet/hiera.yaml.erb',
  $hiera_hierarchy = ['nodes/%{::clientcert}', 'roles/%{::role}', 'common'],
  $hiera_json_datadir = '/var/lib/hiera',
  $hiera_logger = 'console',
  $hiera_merge_behavior = 'deeper',
  $hiera_yaml_datadir = '/var/lib/hiera',
  $puppet_config = '/etc/puppet/puppet.conf',
  $puppet_environment = 'production',
  $puppet_server = $::fqdn,
  $puppet_master_run_with = 'nginx+uwsgi',
) {
  class { '::fuel_project::common' :
    external_host => $external_host,
  }->
  class { '::puppet::master' :
    apply_firewall_rules   => $apply_firewall_rules,
    firewall_allow_sources => $firewall_allow_sources,
    hiera_backends         => $hiera_backends,
    hiera_config           => $hiera_config,
    hiera_config_template  => $hiera_config_template,
    hiera_hierarchy        => $hiera_hierarchy,
    hiera_json_datadir     => $hiera_json_datadir,
    hiera_logger           => $hiera_logger,
    hiera_merge_behavior   => $hiera_merge_behavior,
    hiera_yaml_datadir     => $hiera_yaml_datadir,
    config                 => $puppet_config,
    environment            => $puppet_environment,
    server                 => $puppet_server,
    puppet_master_run_with => $puppet_master_run_with
  }
}
