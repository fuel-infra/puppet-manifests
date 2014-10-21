# Class: opentracker::params
#
class opentracker::params {
  $config_file = '/etc/opentracker.conf'
  $packages = [
    'opentracker',
  ]
  $service = 'opentracker'
}
