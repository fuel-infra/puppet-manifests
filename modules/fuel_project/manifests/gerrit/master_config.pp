# Class fuel_project::gerrit::master_config
#
class fuel_project::gerrit::master_config (
  $host = 'slave.test.local',
  $user = 'gerrit-replicator',
  $identity_file = '~/.ssh/id_rsa',
  $strict_host_key_checking = 'yes',
  $preferred_authentications = 'publickey',
) {

  file { '/var/lib/gerrit/.ssh/config' :
    ensure  => 'present',
    owner   => 'gerrit',
    group   => 'gerrit',
    mode    => '0644',
    content => template('gerrit/config.erb'),
    require => User['gerrit'],
  }
}
