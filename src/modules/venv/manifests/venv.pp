# Define: venv::venv
#
define venv::venv (
  $path,
  $requirements,
  $options,
  $user
) {


  $packages = [
    'git',
    'libffi-dev',
    'postgresql-server-dev-all',
    'python-dev',
  ]

  ensure_packages($packages)

  if (!defined(Package['python-virtualenv'])) {
    package { 'python-virtualenv' :
      ensure => 'present',
    }
  }

  exec { 'venv-create':
    command   => "virtualenv ${options} ${path}",
    user      => $user,
    logoutput => on_failure,
    require   => [
      Package['python-virtualenv'],
    ],
  }

  if $requirements {
    exec { 'venv-requirements':
      command   => "export HOME='/home/${user}' ; \
        . ${path}/bin/activate ; pip install -r ${requirements}",
      user      => $user,
      cwd       => $path,
      logoutput => on_failure,
      require   => Exec['venv-create'],
    }
  }
}
