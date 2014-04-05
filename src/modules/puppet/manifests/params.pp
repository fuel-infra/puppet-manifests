class puppet::params {
  $config = '/etc/puppet/puppet.conf'
  $packages = [
    'puppet',
    'config-puppet-manifests'
  ]
}
