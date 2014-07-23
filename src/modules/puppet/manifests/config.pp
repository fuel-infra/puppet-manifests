class puppet::config {
  include puppet::params

  $config = $puppet::params::config
  $puppet = hiera_hash('puppet')
  $server = $puppet['master']

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
