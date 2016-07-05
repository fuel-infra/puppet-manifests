# Class: log_storage::logstash class
#
# This class deploys logstash instance for log storage.
#
# Parameters:
#   [*logstash_filter_pattern_params*] - logstash filter patter parameters
#   [*beats_host *] - Beats address to bind
#   [*beats_port *] - Beats port to bind
#   [*beats_ssl *] - Enable SSL for Beats
#   [*beats_ssl_ca *] - CA cert content for Beats
#   [*beats_ssl_ca_file *] - CA cert file path for Beats
#   [*beats_certificate *] - Certificate content for Beats
#   [*beats_certificate_file *] - Certificate file path for Beats
#   [*beats_ssl_key*] - Keys file content for Beats
#   [*beats_ssl_key_file*] - Keys file path for Beats
#   [*beats_ssl_verify_mode*] - SSL verify mode for Beats
#   [*beats_type*] - Beats type
#   [*elasticsearch_bind_port*] - Elastic output bind port
#   [*elasticsearch_cacert*] - Elastic output CA certificate path
#   [*elasticsearch_cluster*] - Elastic output cluster
#   [*elasticsearch_hosts*] - Elastic output hosts list having port number specified
#   [*elasticsearch_max_retries*] - Elastic output maximum retries
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
  $beats_host                    = $::fqdn,
  $beats_port                    = 5044,
  $beats_ssl                     = true,
  $beats_ssl_ca                  = $log_storage::params::logstash_beats_ssl_ca,
  $beats_ssl_ca_file             = '/etc/logstash/beats_ssl.ca',
  $beats_ssl_certificate         = $log_storage::params::logstash_beats_ssl_certificate,
  $beats_ssl_certificate_file    = '/etc/logstash/beats_ssl.crt',
  $beats_ssl_key                 = $log_storage::params::logstash_beats_ssl_key,
  $beats_ssl_key_file            = '/etc/logstash/beats_ssl.key',
  $beats_ssl_verify_mode         = 'peer',
  $beats_type                    = 'logs',
  $elasticsearch_bind_port       = undef,
  $elasticsearch_cacert          = undef,
  $elasticsearch_cluster         = undef,
  $elasticsearch_hosts           = "${::fqdn}:9201",
  $elasticsearch_index           = 'logstash-%{+YYYY.MM.dd}-%{IndexType}',
  $elasticsearch_max_retries     = undef,
  $elasticsearch_ssl             = undef,
  $elasticsearch_ssl_cert_verify = undef,
  $elasticsearch_workers         = 2,
  # FIXME: to be removed when Lumberjack will get replaced by Filebeat
  $lumberjack_host               = $::fqdn,
  $lumberjack_port               = '5000',
  $lumberjack_type               = 'logs',
  # /FIXME.
  $logstash_patterns_dir         = '/etc/logstash/patterns',
  # FIXME: to be removed when Lumberjack will get replaced by Filebeat
  $ssl_certificate               = $log_storage::params::logstash_ssl_certificate,
  $ssl_certificate_file          = '/etc/logstash/ssl.crt',
  $ssl_key                       = $log_storage::params::logstash_ssl_key,
  $ssl_key_file                  = '/etc/logstash/ssl.key',
  # /FIXME.
  $user                          = 'logstash',
) inherits log_storage::params {

  ensure_resource('user', $user, {
      'ensure' => 'present',
      'shell'  => '/bin/false',
      'system' => true,
    }
  )

  $logstash_configs = hiera('log_storage::logstash::configfiles', {})
  create_resources('logstash::configfile', $logstash_configs)

  file { "${logstash_patterns_dir}/nginx-access" :
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0664',
    content => template('log_storage/logstash-pattern-nginx-access.erb'),
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  file { "${logstash_patterns_dir}/nginx-error" :
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0664',
    content => template('log_storage/logstash-pattern-nginx-error.erb'),
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  # FIXME: deprecated, to be removed when Lumberjack will get replaced by Filebeat.
  file { "${logstash_patterns_dir}/mysql-slow-log" :
    ensure  => 'present',
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
    ensure  => 'present',
    owner   => $user,
    group   => $user,
    mode    => '0444',
    content => template('log_storage/logstash-pattern-libvirt-qemu-env-log.erb'),
    require => [
      File[$logstash_patterns_dir],
      User[$user],
    ]
  }

  if($ssl_certificate and $ssl_certificate_file) {
    file { $ssl_certificate_file :
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0400',
      content => $ssl_certificate,
      require => [
        File['/etc/logstash/'],
        User[$user],
      ]
    }
  }

  if($ssl_key_file and $ssl_key) {
    file { $ssl_key_file :
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0400',
      content => $ssl_key,
      require => [
        File['/etc/logstash/'],
        User[$user],
      ]
    }
  }
  # /FIXME.

  if ($beats_ssl_ca and $beats_ssl_ca_file) {
    file { $beats_ssl_ca_file :
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0400',
      content => $beats_ssl_ca,
      require => [
        File['/etc/logstash/'],
        User[$user],
      ]
    }
  }

  if ($beats_ssl_certificate and $beats_ssl_certificate_file) {
    file { $beats_ssl_certificate_file :
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0400',
      content => $beats_ssl_certificate,
      require => [
        File['/etc/logstash/'],
        User[$user],
      ]
    }
  }

  if ($beats_ssl_key and $beats_ssl_key_file) {
    file { $beats_ssl_key_file :
      ensure  => 'present',
      owner   => $user,
      group   => $user,
      mode    => '0400',
      content => $beats_ssl_key,
      require => [
        File['/etc/logstash/'],
        User[$user],
      ]
    }
  }

}
