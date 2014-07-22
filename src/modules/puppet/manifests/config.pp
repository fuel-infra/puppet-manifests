class puppet::config {
  include puppet::params

  $config = $puppet::params::config
  $server = $puppet::params::server

  if($puppet_master) {
    file { $config :
      path => $config,
      mode => '0644',
      owner => 'puppet',
      group => 'puppet',
      content => template('puppet/puppet.conf.erb', 'puppet/puppet-master.conf.erb'),
    }
  } else {
    file { $config :
      path => $config,
      mode => '0400',
      owner => 'root',
      group => 'root',
      content => template('puppet/puppet.conf.erb'),
    }
  }
}
