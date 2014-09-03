# Class: puppet::params
#
class puppet::params {
  $apply_firewall_rules = false
  $firewall_allow_sources = []
  $hiera_backends = ['yaml']
  $hiera_config = '/etc/hiera.yaml'
  $hiera_config_template = 'puppet/hiera.yaml.erb'
  $hiera_hierarchy = ['common']
  $hiera_json_datadir = '/var/lib/hiera'
  $hiera_logger = 'console'
  $hiera_merge_behavior = 'deep'
  $hiera_yaml_datadir = '/var/lib/hiera'
  $puppet_agent_package = 'puppet'
  $puppet_agent_service = 'puppet'
  $puppet_config = '/etc/puppet/puppet.conf'
  $puppet_config_template = 'puppet/puppet.conf.erb'
  $puppet_environment = 'production'
  $puppet_master_package = 'puppetmaster'
  $puppet_master_service = 'puppetmaster'
}
