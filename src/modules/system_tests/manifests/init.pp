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

  package { $packages:
    ensure => installed,
  }

  File['allow-unauthenticated.conf'] -> venv::venv['venv-nailgun-tests'] -> Package[$packages] -> Exec['workspace-create']
}
