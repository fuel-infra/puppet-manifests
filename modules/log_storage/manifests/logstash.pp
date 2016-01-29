# Class: log_storage::logstash class
#
# This class deploys logstash instance for log storage.
#
# Parameters:
#   [*logstash_filter_pattern_params*] - logstash filter patter parameters
#   [*elasticsearch_bind_port*] - Elastic output bind port
#   [*elasticsearch_cacert*] - Elastic output CA certificate path
#   [*elasticsearch_cluster*] - Elastic output cluster
#   [*elasticsearch_host*] - Elastic output host
#   [*elasticsearch_max_retries*] - Elastic output maximum retries
#   [*elasticsearch_protocol*] - Elastic output protocol to use
#   [*elasticsearch_port*] - Elastic output port
#   [*elasticsearch_retry_max_items*] - Elastic output maximum items to reply
#   [*elasticsearch_ssl*] - Elastic output SSL connection
#   [*elasticsearch_ssl_cert_verify*] - Elastic output certicate verification
#   [*elasticsearch_workers*] - Elastic output workers to use
#   [*lumberjack_host*] - Lumberjack address to bind
#   [*lumberjack_port*] - Lumberjack port to bind
#   [*lumberjack_type*] - Lumberjack type
#   [*logstash_patterns_dir*] - directory path to Logstash patterns
#   [*ssl_certificate*] - SSL certificate file contents
#   [*ssl_certificate_file*] - SSL certificate file path
#   [*ssl_key*] - SSL key file contents
#   [*ssl_key_file*] - SSL key file path
#   [*user*] - user to deploy logstash
#
class log_storage::logstash (
  $logstash_filter_pattern_params,
  $elasticsearch_bind_port       = undef,
  $elasticsearch_cacert          = undef,
  $elasticsearch_cluster         = undef,
  $elasticsearch_host            = $::fqdn,
  $elasticsearch_max_retries     = undef,
  $elasticsearch_protocol        = 'node',
  $elasticsearch_port            = undef,
  $elasticsearch_retry_max_items = undef,
  $elasticsearch_ssl             = undef,
  $elasticsearch_ssl_cert_verify = undef,
  $elasticsearch_workers         = 2,
  $lumberjack_host               = $::fqdn,
  $lumberjack_port               = '5000',
  $lumberjack_type               = 'logs',
  $logstash_patterns_dir         = '/etc/logstash/patterns',
  $ssl_certificate               = $log_storage::params::logstash_ssl_certificate,
  $ssl_certificate_file          = '/etc/logstash/ssl.crt',
  $ssl_key                       = $log_storage::params::logstash_ssl_key,
  $ssl_key_file                  = '/etc/logstash/ssl.key',
  $user                          = 'logstash',
) inherits log_storage::params {

  ensure_resource('user', $user, {
      'ensure' => 'present',
      'shell'  => '/bin/false',
      'system' => true,
    }
  )

  logstash::configfile { 'logstash-input-lumberjack' :
    content => template('log_storage/logstash-input-lumberjack.conf.erb'),
    order   => 10,
  }

  logstash::configfile { 'logstash-filter-syslog':
    content => template('log_storage/logstash-filter-syslog.conf.erb'),
    order   => 20,
  }

  logstash::configfile { 'logstash-filter-nginx-access' :
    content => template('log_storage/logstash-filter-nginx-access.conf.erb'),
    order   => 21,
  }

  logstash::configfile { 'logstash-filter-nginx-error' :
    content => template('log_storage/logstash-filter-nginx-error.conf.erb'),
    order   => 22,
  }

  logstash::configfile { 'logstash-filter-mysql-slow-log' :
    content => template('log_storage/logstash-filter-mysql-slow-log.conf.erb'),
    order   => 23,
  }

  logstash::configfile { 'logstash-filter-libvirt-qemu-env-log' :
    content => template('log_storage/logstash-filter-libvirt-qemu-env-log.conf.erb'),
    order   => 24,
  }

  logstash::configfile { 'logstash-output-elasticsearch' :
    content => template('log_storage/logstash-output-elasticsearch.conf.erb'),
    order   => 40,
  }

  file { "${logstash_patterns_dir}/nginx-access" :
    owner   => $user,
    group   => $user,
    mode    => '0664',
    content => template('log_storage/logstash-pattern-nginx-access.erb'),
    replace => true,
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  file { "${logstash_patterns_dir}/nginx-error" :
    owner   => $user,
    group   => $user,
    mode    => '0664',
    content => template('log_storage/logstash-pattern-nginx-error.erb'),
    replace => true,
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  file { "${logstash_patterns_dir}/mysql-slow-log" :
    owner   => $user,
    group   => $user,
    mode    => '0444',
    content => template('log_storage/logstash-pattern-mysql-slow-log.erb'),
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  file { "${logstash_patterns_dir}/libvirt-qemu-env-log" :
    owner   => $user,
    group   => $user,
    mode    => '0444',
    content => template('log_storage/logstash-pattern-libvirt-qemu-env-log.erb'),
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  file { $ssl_certificate_file :
    owner   => $user,
    group   => $user,
    mode    => '0400',
    content => $ssl_certificate,
    replace => true,
    require => [
      File['/etc/logstash/'],
      User[$user],
    ]
  }

  file { $ssl_key_file :
    owner   => $user,
    group   => $user,
    mode    => '0400',
    content => $ssl_key,
    replace => true,
    require => [
      File['/etc/logstash/'],
      User[$user],
    ]
  }

}
