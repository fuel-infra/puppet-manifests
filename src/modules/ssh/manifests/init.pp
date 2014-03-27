class ssh {
  include ssh::params

  $root_keys = $ssh::params::root_keys
  $service = $ssh::params::service
  $sshd_config = $ssh::params::sshd_config

  create_resources(ssh_authorized_key, $root_keys, {ensure => present, user => 'root'})

 file { $sshd_config :
    path => $sshd_config,
    mode => '0644',
    owner => 'root',
    group => 'root',
    content => template('ssh/sshd_config.erb'),
  }

  service { $service :
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => false,
  }

  if $external_host {
    Class['firewall_defaults::pre'] ->
    firewall { '100 allow ssh connections' :
      dport => 22,
      action => 'accept',
    }
  }

  File[$sshd_config]~>
   Service[$service]
}

