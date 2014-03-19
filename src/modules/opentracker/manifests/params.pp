class opentracker::params {
  $config_file = '/etc/opentracker.conf'
  $pre_packages = [
    'libbsd-resource-perl'
  ]
  $packages = [
    'opentracker',
  ]
  $service = 'opentracker'
}
