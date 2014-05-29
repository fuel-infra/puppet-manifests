class system_tests {
  include postgresql
  include system_tests::params
  include venv
  include packages

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

  Class['dpkg'] ->
    Package[$packages] ->
    Venv::Venv['venv-nailgun-tests'] ->
    Class['postgresql'] ->
    Exec['devops-syncdb'] ->
    Exec['devops-migrate'] ->
    Exec['workspace-create']
}
