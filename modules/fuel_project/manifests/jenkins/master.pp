# Class: fuel_project::jenkins::master
#
class fuel_project::jenkins::master (
  $firewall_enable      = false,
  $install_label_dumper = false,
  $install_plugins      = false,
  $install_zabbix_item  = false,
  $jobs_dir             = '/var/lib/jenkins/jobs/',
  $log_gzip_cron_name   = 'jenkins-log-compression',
  $log_gzip_cron_params = {},
  $log_gzip_days        = '1',
  $log_gzip_enable      = false,
  $log_gzip_threads     = '1',
  $service_fqdn         = $::fqdn,
) {
  class { '::fuel_project::common':
    external_host => $firewall_enable,
  }
  class { '::jenkins::master':
    apply_firewall_rules => $firewall_enable,
    install_zabbix_item  => $install_zabbix_item,
    service_fqdn         => $service_fqdn,
  }
  if($install_plugins) {
    package { 'jenkins-plugins' :
      ensure  => present,
      require => Service['jenkins'],
    }
  }
  if($log_gzip_enable) {
    ensure_packages('pigz')
    create_resources('cron', { "${log_gzip_cron_name}" => $log_gzip_cron_params }, {
        ensure  => 'present',
        command => "/usr/bin/flock -xn /var/lock/${log_gzip_cron_name}.lock /usr/bin/find ${jobs_dir} -name 'log' -regex '.*/builds/[0-9]+/log' -mtime +${log_gzip_days} -exec pigz -p ${log_gzip_threads} '{}' \; 2>&1 | logger -t jenkins-log-compression",
        user    => 'jenkins',
        minute  => '30',
        hour    => '2',
    })
  }
}
