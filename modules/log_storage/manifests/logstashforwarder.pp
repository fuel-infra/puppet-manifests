# Class: log_storage::logstashforwarder class
#
# This class deploys logstash forwarder.
#
# Parameters:
#   [*files*] - files to be read by forwarder
#   [*ssl_ca_file*] - SSL CA file path to verify logstash
#   [*ssl_ca*] - SSL CA file contents
#
class log_storage::logstashforwarder (
  $files       = undef,
  $ssl_ca_file = '/etc/logstashforwarder/ssl.ca',
  $ssl_ca      = $log_storage::params::logstash_ssl_ca,
) inherits log_storage::params {

  class { '::logstashforwarder' : }

  create_resources(logstashforwarder::file, $files)

  if ($ssl_ca_file) {
    ensure_resource('file', '/etc/logstashforwarder')

    file { $ssl_ca_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_ca,
      replace => true,
      require => File['/etc/logstashforwarder'],
    }
  }

}