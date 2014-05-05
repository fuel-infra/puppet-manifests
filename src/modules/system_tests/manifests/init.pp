class system_tests {
  include system_tests::params

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
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
    logoutput => on_failure,
  }

  exec { 'devops-migrate' :
    command => '. /home/jenkins/venv-nailgun-tests/bin/activate ; django-admin migrate devops --settings=devops.settings',
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
    logoutput => on_failure,
  }

  package { $packages:
    ensure => installed,
  }

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

