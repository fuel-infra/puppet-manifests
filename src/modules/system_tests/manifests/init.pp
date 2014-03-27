class system_tests {
  include system_tests::params

  $packages = $system_tests::params::packages
  $workspace = $system_tests::params::workspace

  exec { 'workspace-create':
    command => "mkdir -p ${workspace}",
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
  }

  exec { 'devops-syncdb' :
    command => '. /home/jenkins/venv-nailgun-tests/bin/activate ; django-admin syncdb --settings=devops.settings',
    provider => 'shell',
    user => 'jenkins',
    cwd => '/tmp',
  }

  package { $packages:
    ensure => installed,
  }

  Class['dpkg'] ->
    Class['jenkins_swarm_slave'] ->
    Package[$packages] -> 
    Venv::Venv['venv-nailgun-tests'] ->
    Class['postgresql'] -> 
    Exec['devops-syncdb'] ->
    Exec['workspace-create']
}
