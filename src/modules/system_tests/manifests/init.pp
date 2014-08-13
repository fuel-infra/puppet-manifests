class system_tests {
  include system_tests::params
  include venv

  $sudo_commands = $system_tests::params::sudo_commands
  $workspace = $system_tests::params::workspace

  $packages = [
    # dependencies
    'libevent-dev',
    'python-anyjson',
    'python-glanceclient',
    'python-ipaddr',
    'python-keystoneclient',
    'python-novaclient',
    'python-paramiko',
    'python-proboscis',
    'python-seed-cleaner',
    'python-seed-client',
    'python-xmlbuilder',
    'python-yaml',

    # diagnostic utilities
    'htop',
    'sysstat',
    'dstat',
    'vncviewer',
  ]

  each($packages) |$package| {
    if ! defined(Package[$package]){
      package { $package :
        ensure => installed,
      }
    }
  }

  exec { 'workspace-create' :
    command => "mkdir -p ${workspace}",
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
    logoutput => on_failure,
  }

  class { 'devops' :
    install_cron_cleanup => true,
  }

  file { '/home/jenkins/venv-nailgun-tests/lib/python2.7/site-packages/devops/local_settings.py' :
    ensure   => link,
    target   => '/etc/devops/local_settings.py',
    require  => [ Class['devops'],
                  Venv::Venv['venv-nailgun-tests']
                ]
  }

  file { '/etc/sudoers.d/systest' :
    content => template('system_tests/sudoers.erb'),
    mode => '0600',
  }

  file { '/usr/local/bin/seed-downloads-cleanup.sh' :
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source => 'puppet:///modules/fuel_project/bin/seed-downloads-cleanup.sh',
    require => Package['python-seed-cleaner'],
  }

  cron { 'seed-downloads-cleanup' :
    command => '/usr/local/bin/seed-downloads-cleanup.sh | logger -t seed-downloads-cleanup',
    user    => root,
    hour    => '*/4',
    minute  => 0,
    require => File['/usr/local/bin/seed-downloads-cleanup.sh'],
  }

  # FIXME: Please pass firewall rules as a parameters to class.
  if $external_host {
    $firewall = hiera_hash('firewall')
    $local_networks = $firewall['local_networks']

    each($local_networks) |$ip| {
      firewall { "0100 allow local connections - src ${ip}" :
        source => $ip,
        action => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }

  Class['dpkg']->
    Package[$packages]->
    Venv::Venv['venv-nailgun-tests']->
    Exec['workspace-create']
}
