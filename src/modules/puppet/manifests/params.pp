# Class: puppet::params
#
class puppet::params {
  $agent_packages = [
    'puppet',
  ]

  $config = '/etc/puppet/puppet.conf'

  $master_packages = [
    'puppetmaster'
  ]

  $master_service = 'puppetmaster'

  $service = 'puppet'
}
