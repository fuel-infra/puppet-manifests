# Class: ssh::authorized_keys
class ssh::authorized_keys {
  $keys = hiera_hash('ssh::authorized_keys::keys', {})
  # FIXME: It's ugly dirty hack to do purge_ssh_key with puppet 3.4.x :(
  # We could replace after upgrade to 3.7+ with:
  # user { 'root' :
  #   purge_ssh_key => true,
  # }
  #
  file { '/root/.ssh' :
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }
  exec { 'echo "" > /root/.ssh/authorized_keys' :
    user    => 'root',
    require => File['/root/.ssh'],
  }
  # /FIXME
  create_resources(ssh_authorized_key,
    $keys, {
      ensure  => present,
      user    => 'root',
      require => Exec['echo "" > /root/.ssh/authorized_keys'],
    }
  )
}
