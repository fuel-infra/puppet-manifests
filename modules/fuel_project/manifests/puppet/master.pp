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
  $enable_update_cronjob   = true,
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
  include ::fuel_project::common
  include ::puppet::master
  class { '::fuel_project::nginx' :
    require => Class['::fuel_project::common'],
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
      command => '/usr/bin/timeout -k340 300 /usr/local/bin/puppet-manifests-update.sh 2>&1 | logger -t puppet-manifests-update',
      user    => 'root',
      minute  => '*/10',
      require => File['/usr/local/bin/puppet-manifests-update.sh'],
    }
  }
}
