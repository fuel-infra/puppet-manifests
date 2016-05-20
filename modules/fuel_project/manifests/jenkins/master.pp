# Class: fuel_project::jenkins::master
#
# This class deploys full Jenkins master instance.
#
# Parameters:
#   [*cron_jobs*] - hash for creating cron jobs
#   [*firewall_enable*] - enable embedded firewall rules
#   [*install_label_dumper*] - unused variable
#   [*install_zabbix_item*] - install Jenkins items for Zabbix
#   [*jenkins_libdir*] - path to Jenkins lib directory
#   [*jobs_dir*] - path to directory with Jenkins jobs
#   [*known_hosts*] - known hosts to be added to known_hosts file
#     Example:
#       'review.test.local':
#         'host': 'review.test.local'
#         'port': 29418
#   [*known_hosts_overwrite*] - erase known_hosts file before adding to it
#   [*log_gzip_enable*] - enable gzip process for old files
#   [*service_fqdn*] - service FQDN
#
class fuel_project::jenkins::master (
  $cron_jobs             = undef,
  $firewall_enable       = false,
  $install_label_dumper  = false,
  $install_plugins       = false,
  $install_zabbix_item   = false,
  $jenkins_libdir        = '/var/lib/jenkins',
  $jobs_dir              = '/var/lib/jenkins/jobs/',
  $known_hosts           = {},
  $known_hosts_overwrite = false,
  $log_gzip_enable       = false,
  $service_fqdn          = $::fqdn,
) {
  class { '::fuel_project::common':
    external_host => $firewall_enable,
  }
  class { '::jenkins::master':
    apply_firewall_rules => $firewall_enable,
    install_zabbix_item  => $install_zabbix_item,
    service_fqdn         => $service_fqdn,
    install_plugins      => $install_plugins,
  }
  if($log_gzip_enable) {
    ensure_packages('pigz')
  }

  # error-pages
  ensure_packages('error-pages')

  ::Nginx::Resource::Vhost <| title == 'jenkins' |> {
    vhost_cfg_append    => {
      'error_page 404'         => '/fuel-infra/404.html',
      'error_page 500 502 504' => '/fuel-infra/5xx.html',
    }
  }

  # error pages for jenkins
  ::nginx::resource::location { 'jenkins-error-pages' :
    ensure   => 'present',
    vhost    => 'jenkins',
    location => '~ ^\/(mirantis|fuel-infra)\/(403|404|5xx)\.html$',
    ssl      => true,
    ssl_only => true,
    www_root => '/usr/share/error_pages',
    require  => Package['error-pages'],
  }

  $jenkins_additional_ssh_keys = hiera_hash('fuel_project::jenkins::master::jenkins_additional_ssh_keys', {})

  if($jenkins_additional_ssh_keys) {
    create_resources(file, $jenkins_additional_ssh_keys, {
      ensure  => 'present',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      require => [
        User['jenkins'],
        File["${jenkins_libdir}/.ssh"],
      ],
    })
  }

  if($cron_jobs) {
    create_resources(cron, $cron_jobs, {
      ensure  => 'present',
      user    => 'jenkins',
      require => User['jenkins'],
    })
  }

  # 'known_hosts' manage
  if ($known_hosts) {
    create_resources('ssh::known_host', $known_hosts, {
      user      => 'jenkins',
      overwrite => $known_hosts_overwrite,
      require   => User['jenkins'],
    })
  }

}
