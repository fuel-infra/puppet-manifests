# Class: log_storage::filebeat class
#
# This class deploys filebeat log shipper.
#
# Parameters:
#
#   [*beats_ssl_ca*] - SSL CA file contents
#   [*beats_ssl_ca_file*] - SSL CA file path to verify logstash
#   [*beats_ssl_certificate*] - SSL certificate file contents
#   [*beats_ssl_certificate_file*] - SSL certificate file path
#   [*beats_ssl_key*] - SSL key file contents
#   [*beats_ssl_key_file*] - SSL key file path
#
class log_storage::filebeat (
  $beats_ssl_ca               = $log_storage::params::logstash_beats_ssl_ca,
  $beats_ssl_ca_file          = '/etc/filebeat/ssl.ca',
  $beats_ssl_certificate      = undef,
  $beats_ssl_certificate_file = '/etc/filebeat/ssl.crt',
  $beats_ssl_key              = undef,
  $beats_ssl_key_file         = '/etc/filebeat/ssl.key',
) inherits log_storage::params {

  package { 'logstash-forwarder' :
    ensure => 'purged',
  }

  file { '/etc/filebeat' :
    ensure => 'directory',
  }

  if($beats_ssl_ca and $beats_ssl_ca_file) {
    file { $beats_ssl_ca_file :
      ensure  => 'present',
      content => $beats_ssl_ca,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      require => File['/etc/filebeat'],
    }
  }

  if($beats_ssl_certificate and $beats_ssl_certificate_file) {
    file { $beats_ssl_certificate_file :
      ensure  => 'present',
      content => $beats_ssl_certificate,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      require => File['/etc/filebeat'],
    }
  }

  if($beats_ssl_key and $beats_ssl_key_file) {
    file { $beats_ssl_key_file :
      ensure  => 'present',
      content => $beats_ssl_key,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      require => File['/etc/filebeat'],
    }
  }

  include '::filebeat'
}
