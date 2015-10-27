# log_storage::logstash class
#
class log_storage::logstash (
  $nginx_filter_access_message,
  $nginx_filter_access_type,
  $nginx_filter_error_message,
  $nginx_filter_error_type,
  $syslog_filter_match,
  $elasticsearch_bind_port       = undef,
  $elasticsearch_cacert          = undef,
  $elasticsearch_cluster         = undef,
  $elasticsearch_host            = $::fqdn,
  $elasticsearch_protocol        = 'node',
  $elasticsearch_port            = undef,
  $elasticsearch_ssl             = undef,
  $elasticsearch_ssl_cert_verify = undef,
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
