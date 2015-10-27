# log_storage::params class
#
class log_storage::params (
  $logstash_ssl_ca,
  $logstash_ssl_certificate,
  $logstash_ssl_key,
  $nginx_ssl_certificate = undef,
  $nginx_ssl_key         = undef,
  $nginx_ssl_ca          = undef,
) { }

