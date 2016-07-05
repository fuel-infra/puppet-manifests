# Class: log_storage::params class
#
# This class stores default parameters for log storage.
#
# Please see parameters description in top modules.
#
class log_storage::params (
  $logstash_beats_ssl_ca,
  $logstash_beats_ssl_certificate,
  $logstash_beats_ssl_key,
  # FIXME: deprecated, to be removed when Lumberjack will get replaced by Filebeat.
  $logstash_ssl_ca               = undef,
  $logstash_ssl_certificate      = undef,
  $logstash_ssl_key              = undef,
  # /FIXME.
  $nginx_ssl_elastic_certificate = undef,
  $nginx_ssl_elastic_key         = undef,
  $nginx_ssl_kibana_certificate  = undef,
  $nginx_ssl_kibana_key          = undef,
  ) { }
