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

  file { 'cron-cleanup.sh' :
    path => '/usr/bin/cron-cleanup.sh',
    owner => 'root',
    group => 'root',
    mode => '0755',
    content => template('system_tests/cron-cleanup.sh.erb'),
  }

  cron { 'cron-cleanup' :
    command => '/usr/bin/cron-cleanup.sh | logger -t cron-cleanup',
    user => root,
    hour => '*/4',
    minute => 0,
  }

  Class['dpkg']->
    Package[$packages]->
    Venv::Venv['venv-nailgun-tests']->
    Class['postgresql']->
    Exec['devops-syncdb']->
    Exec['devops-migrate']->
    Exec['workspace-create']->
    File['cron-cleanup.sh']->
    Cron['cron-cleanup']
}
