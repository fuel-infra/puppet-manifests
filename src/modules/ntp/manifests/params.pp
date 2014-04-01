class ntp::params {
  $config = '/etc/ntp.conf'
  $packages = [
    'ntp',
    'tzdata',
  ]
  $restrict = [
    '127.0.0.1',
    '::1',
  ]
  $servers = [
    'pool.ntp.org',
  ]
  $service = 'ntp'
}
