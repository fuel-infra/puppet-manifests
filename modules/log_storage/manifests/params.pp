# Class: log_storage::params class
#
# This class stores default parameters for log storage.
#
# Please see parameters description in top modules.
#
class log_storage::params (
  $logstash_ssl_ca,
  $logstash_ssl_certificate,
  $logstash_ssl_key,
  $nginx_ssl_elastic_certificate = undef,
  $nginx_ssl_elastic_key         = undef,
  $nginx_ssl_kibana_certificate  = undef,
  $nginx_ssl_kibana_key          = undef,
  ) { }