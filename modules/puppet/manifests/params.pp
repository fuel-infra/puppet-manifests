# Class: puppet::params
#
# This class defines parameters for Puppet classes.
#
# Parameters:
#   [*agent_config_template*] - agent config file template
#   [*agent_package*] - agent package name
#   [*agent_service*] - agent service name
#   [*apply_firewall_rules*] - apply embedded firewall values
#   [*archive_file_server*] - the file bucket server to archive files to
#   [*archive_files*] - use files archive
#   [*autosign*] - automatically sign new hosts
#   [*classfile*] - classes associated with the retrieved configuration
#   [*config*] - Puppet configuration file path
#   [*config_template*] - Puppet configuration file template
#   [*environment*] - environment value for Puppet
#   [*firewall_allow_sources*] - addresses to allow service connections from
#   [*graph*] - create dot graph files for the different configuration graphs
#   [*hiera_backends*] - supported hiera backends
#   [*hiera_config*] - hiera configuration file path
#   [*hiera_config_template*] - hiera configuration file template
#   [*hiera_hierarchy*] - hiera hierarchy list
#   [*hiera_json_datadir*] - hiera json data directory
#   [*hiera_logger*] - hiera logger type
#   [*hiera_merge_behavior*] - must be one of the following:
#     native (default) - merge top-level keys only
#     deep - merge recursively; in the event of conflicting keys, allow lower
#       priority values to win
#     deeper - merge recursively; in the event of a conflict, allow higher
#       priority values to win
#   [*hiera_yaml_datadir*] - hiera directory with yaml files
#   [*localconfig*] - where puppet agent caches the local configuration
#   [*logdir*] - log directory
#   [*master_config_template*] - puppet-master config file template
#   [*master_package*] - puppet-master package name
#   [*master_service*] - puppet-master service name
#   [*modulepath*] - search path for modules
#   [*parser*] - parser variable value for config file
#   [*pluginsync*] - sync plugins with a central server
#   [*puppet_agent_package*] - Puppet agent package name
#   [*puppet_agent_service*] - Puppet agent service name
#   [*report*] - send reports after every transaction
#   [*rundir*] - Puppet run directory
#   [*server*] - server variable in Puppet configuration file
#   [*show_diff*] - log and report a contextual diff when files are replaced
#   [*ssldir*] - directory to keep ssl files
#   [*vardir*] - Puppet var directory path
#   [*factpath*] - Puppet facter lib directory
#
class puppet::params {
  $agent_config_template  = 'puppet/puppet.conf.erb'
  $agent_package          = 'puppet'
  $agent_service          = 'puppet'
  $apply_firewall_rules   = false
  $archive_file_server    = undef
  $archive_files          = false
  $autosign               = false
  $classfile              = undef
  $config                 = '/etc/puppet/puppet.conf'
  $config_template        = 'puppet/puppet.conf.erb'
  $environment            = undef
  $firewall_allow_sources = {}
  $graph                  = undef
  $hiera_backends         = ['yaml']
  $hiera_config           = '/etc/puppet/hiera.yaml'
  $hiera_config_template  = 'puppet/hiera.yaml.erb'
  $hiera_hierarchy        = ['common']
  $hiera_json_datadir     = '/var/lib/hiera'
  $hiera_logger           = 'console'
  $hiera_merge_behavior   = 'deep'
  $hiera_yaml_datadir     = '/var/lib/hiera'
  $localconfig            = undef
  $logdir                 = '/var/log/puppet'
  $master_config_template = 'puppet/puppet-master.conf.erb'
  $master_package         = 'puppetmaster'
  $master_service         = 'puppetmaster'
  $modulepath             = undef
  $parser                 = undef
  $pluginsync             = true
  $puppet_agent_package   = 'puppet'
  $puppet_agent_service   = 'puppet'
  $report                 = true
  $rundir                 = '/var/run/puppet'
  $server                 = undef
  $show_diff              = true
  $ssldir                 = '/var/lib/puppet/ssl'
  $vardir                 = '/var/lib/puppet'
  $factpath               = "${vardir}/lib/facter"
}
