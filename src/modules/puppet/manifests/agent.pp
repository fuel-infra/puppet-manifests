# Class: puppet::agent
#
class puppet::agent (
  $puppet_agent_package = 'puppet',
  $puppet_agent_service = 'puppet',
  $puppet_config = '/etc/puppet/puppet.conf',
  $puppet_server = '',
) {
  file { $puppet_config :
    ensure  => 'present',
    mode    => '0400',
    owner   => 'root',
    group   => 'root',
    content => template('puppet/puppet.conf.erb'),
  }

  if (!defined(Package['puppet'])) {
    package { 'puppet' :
      ensure => 'present',
    }
  }

  service { $puppet_agent_service :
    ensure  => 'stopped',
    enable  => false,
    require => Package['puppet']
  }
}
