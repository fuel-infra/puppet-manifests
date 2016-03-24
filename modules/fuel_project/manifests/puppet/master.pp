# Class: fuel_project::puppet::master
#
# This class deploys fully functional Puppet Master instance with all the
# requirements.
#
# Parameters:
#   [*apply_firewall_rules*] - use embedded firewall rules
#   [*enable_update_cronjob*] - enable cron job which periodically updates
#     puppet configuration using remote repository
#   [*external_host*] - apply firewall rules for common services
#   [*firewall_allow_sources*] - sources which are allowed to contact this
#     service
#   [*hiera_backends*] - backends used by hiera
#   [*hiera_config*] - hiera configuration file path
#   [*hiera_config_template*] - hiera configuration file template
#   [*hiera_hierarchy*] - hierarchy of loading values by hiera
#   [*hiera_json_datadir*] - hiera directory with json files
#   [*hiera_logger*] - where to log hiera events
#   [*hiera_merge_behavior*] - must be one of the following:
#     native (default) - merge top-level keys only
#     deep - merge recursively; in the event of conflicting keys, allow lower
#       priority values to win
#     deeper - merge recursively; in the event of a conflict, allow higher
#       priority values to win
#   [*hiera_yaml_datadir*] - hiera directory with yaml files
#   [*manifests_binpath*] - path to store Puppet helper scripts
#   [*manifests_branch*] - branch which will be synchronized from remote repo
#   [*manifests_manifestspath*] - path to manifest directory
#   [*manifests_modulespath*] - path to modules directory
#   [*manifests_repo*] - remote repository with modules to fetch
#   [*manifests_tmpdir*] - temporary directory
#   [*puppet_config*] - Puppet configuration file path
#   [*puppet_environment*] - environment type to use by Puppet
#   [*puppet_master_run_with*] - Puppet serving method
#   [*puppet_server*] - Puppet service FQDN
#
class fuel_project::puppet::master (
  $apply_firewall_rules    = false,
  $enable_update_cronjob   = true,
  $external_host           = false,
  $firewall_allow_sources  = {},
  $hiera_backends          = ['yaml'],
  $hiera_config            = '/etc/hiera.yaml',
  $hiera_config_template   = 'puppet/hiera.yaml.erb',
  $hiera_hierarchy         = ['nodes/%{::clientcert}', 'roles/%{::role}', 'locations/%{::location}', 'distros/%{::osfamily}', 'common'],
  $hiera_json_datadir      = '/var/lib/hiera',
  $hiera_logger            = 'console',
  $hiera_merge_behavior    = 'deeper',
  $hiera_yaml_datadir      = '/var/lib/hiera',
  $manifests_binpath       = '/etc/puppet/bin',
  $manifests_branch        = 'master',
  $manifests_manifestspath = '/etc/puppet/manifests',
  $manifests_modulespath   = '/etc/puppet/modules',
  $manifests_repo          = 'https://github.com/fuel-infra/puppet-manifests.git',
  $manifests_tmpdir        = '/tmp/puppet-manifests',
  $puppet_config           = '/etc/puppet/puppet.conf',
  $puppet_environment      = 'production',
  $puppet_master_run_with  = 'nginx+uwsgi',
  $puppet_server           = $::fqdn,
) {
  class { '::fuel_project::common' :
    external_host => $external_host,
  }
  class { '::fuel_project::nginx' :
    require => Class['::fuel_project::common'],
  }
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
    puppet_master_run_with => $puppet_master_run_with,
    require                => [
      Class['::fuel_project::common'],
      Class['::fuel_project::nginx'],
    ],
  }
  file { '/usr/local/bin/puppet-manifests-update.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('fuel_project/puppet/master/puppet-manifests-update.sh.erb')
  }
  if ($enable_update_cronjob) {
    cron { 'puppet-manifests-update' :
      command => '/usr/bin/timeout -k80 60 /usr/local/bin/puppet-manifests-update.sh 2>&1 | logger -t puppet-manifests-update',
      user    => 'root',
      minute  => '*/5',
      require => File['/usr/local/bin/puppet-manifests-update.sh'],
    }
  }
}
