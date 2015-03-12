# Class: fuel_project::roles::ns
#
class fuel_project::roles::ns (
  $dns_repo,
  $role                             = 'master',
  $dns_branch                       = 'master',
  $dns_tmpdir                       = '/tmp/ns-update',
  $target_path                      = '/var/cache/bind',
  $dns_checkout_private_key_content = undef,
) {
  class { '::fuel_project::common' :}
  class { '::bind' :}
  ::bind::server::conf { '/etc/bind/named.conf' :
    require => Class['::bind'],
  }

  if ($role == 'master') {
    ensure_packages(['git'])

    file { '/usr/local/bin/ns-update.sh' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('fuel_project/roles/ns/ns-update.sh.erb'),
      require => [
        Class['::bind'],
        ::Bind::Server::Conf['/etc/bind/named.conf'],
        Package['git'],
      ],
    }

    cron { 'ns-update' :
      command => '/usr/bin/timeout -k80 60 /usr/local/bin/ns-update.sh 2>&1 | logger -t ns-update',
      user    => 'root',
      minute  => '*/5',
      require => File['/usr/local/bin/ns-update.sh'],
    }
  }

  if ($dns_checkout_private_key_content) {
    file { '/root/.ssh' :
      ensure => 'directory',
      mode   => '0500',
      owner  => 'root',
      group  => 'root',
    }

    file { '/root/.ssh/id_rsa' :
      ensure  => 'present',
      content => $dns_checkout_private_key_content,
      mode    => '0400',
      owner   => 'root',
      group   => 'root',
      require => File['/root/.ssh'],
    }
  }
}
