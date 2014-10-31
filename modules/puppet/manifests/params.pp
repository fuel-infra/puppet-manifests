# Class: puppet::params
#
class puppet::params {
  $apply_firewall_rules = false
  $firewall_allow_sources = {}
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
  $config_template = 'puppet/puppet.conf.erb'
  $master_package = 'puppetmaster'
  $master_service = 'puppetmaster'


  $autosign = false
  $agent_config_template = 'puppet/puppet.conf.erb'
  $master_config_template = 'puppet/puppet-master.conf.erb'
  $agent_package = 'puppet'
  $agent_service = 'puppet'
  $config = '/etc/puppet/puppet.conf'
  $server = undef
  $ssldir = '/var/lib/puppet/ssl'
  $vardir = '/var/lib/puppet'
  $parser = undef
  $rundir = '/var/run/puppet'
  $logdir = '/var/log/puppet'
  $factpath = "${vardir}/lib/facter"
  $pluginsync = true
  $report = true
  $show_diff = true
  $modulepath = undef
  $archive_files = false
  $archive_file_server = undef
  $classfile = undef
  $localconfig = undef
  $graph = undef
  $environment = undef
}
