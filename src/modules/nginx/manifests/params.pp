class nginx::params {
  $packages = [
    'nginx',
    'nginx-common',
    'nginx-full',
  ]
  $service = 'nginx'
}
