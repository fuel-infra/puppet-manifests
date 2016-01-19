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

}
