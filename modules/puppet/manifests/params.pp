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
#   [*hiera_config*] - hiera configuration file path
#   [*localconfig*] - where puppet agent caches the local configuration
#   [*logdir*] - log directory
#   [*master_config_template*] - puppet-master config file template
#   [*master_packages*] - puppet-master package name
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
  $hiera                  = {
    ':hiera_backends'   => ['yaml', 'json'],
    ':hiera_hierarchy'  => ['common'],
    ':yaml' => {
      ':datadir' => '/var/lib/hiera',
    },
    ':json'             => {
      ':datadir' => '/var/lib/hiera'
    },
    ':logger'           => 'console',
    ':merge_behavior'   => 'deep',
  }
  $hiera_config           = '/etc/puppet/hiera.yaml'
  $localconfig            = undef
  $logdir                 = '/var/log/puppet'
  $master_config_template = 'puppet/puppet-master.conf.erb'
  $master_packages        = [ 'puppetmaster', 'hiera' ]
  $master_run_with        = 'webrick'
  $master_service         = $master_run_with ? {
    'nginx+uwsgi' => 'uwsgi',
    default       => 'puppetmaster',
  }
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
