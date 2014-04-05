class puppet {
  include puppet::params

  $config = $puppet::params::config
  $packages = $puppet::params::packages

  package { $packages :
    ensure => latest,
  }

  file { $config :
    path => $config,
    mode => '0400',
    owner => 'root',
    group => 'root',
    content => template('puppet/puppet.conf.erb'),
  }
}
