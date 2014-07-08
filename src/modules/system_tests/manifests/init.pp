class system_tests {
  include postgresql
  include system_tests::params
  include venv
  include virtual::packages

  $packages = $system_tests::params::packages
  $sudo_commands = $system_tests::params::sudo_commands
  $workspace = $system_tests::params::workspace

  exec { 'workspace-create':
    command => "mkdir -p ${workspace}",
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
    logoutput => on_failure,
  }

  exec { 'devops-syncdb' :
    command => '. /home/jenkins/venv-nailgun-tests/bin/activate ; django-admin syncdb --settings=devops.settings',
    user => 'jenkins',
    logoutput => on_failure,
  }

  exec { 'devops-migrate' :
    command => '. /home/jenkins/venv-nailgun-tests/bin/activate ; django-admin migrate devops --settings=devops.settings',
    user => 'jenkins',
    logoutput => on_failure,
  }

  realize Package[$packages]

  file { '/etc/sudoers.d/systest' :
    content => template('system_tests/sudoers.erb'),
    mode => '0600',
  }

  file { 'seed-downloads-cleanup.sh' :
    path => '/usr/local/bin/seed-downloads-cleanup.sh',
    owner => 'root',
    group => 'root',
    mode => '0755',
    content => template('system_tests/seed-downloads-cleanup.sh.erb'),
  }

  cron { 'seed-downloads-cleanup' :
    command => '/usr/local/bin/seed-downloads-cleanup.sh | logger -t seed-downloads-cleanup',
    user => root,
    hour => '*/4',
    minute => 0,
  }

  file { 'devops-env-cleanup.sh' :
    path => '/usr/local/bin/devops-env-cleanup.sh',
    owner => 'root',
    group => 'root',
    mode => '0755',
    content => template('system_tests/devops-env-cleanup.sh.erb'),
  }

  cron { 'devops-env-cleanup' :
    command => '/usr/local/bin/devops-env-cleanup.sh | logger -t devops-env-cleanup',
    user => root,
    hour => 16, # 16:00 UTC
    minute => 0,
  }

  # FIXME: Temporary required to clean up old files and cronjobs
  file { '/usr/bin/cron-cleanup.sh' :
    ensure => absent,
  }->
  cron { 'cron-cleanup' :
    ensure => absent,
  }
  # /FIXME

  Class['dpkg']->
    Package[$packages]->
    Venv::Venv['venv-nailgun-tests']->
    Class['postgresql']->
    Exec['devops-syncdb']->
    Exec['devops-migrate']->
    Exec['workspace-create']->
    File['seed-downloads-cleanup.sh']->
    Cron['seed-downloads-cleanup']->
    File['devops-env-cleanup.sh']->
    Cron['devops-env-cleanup']
}
