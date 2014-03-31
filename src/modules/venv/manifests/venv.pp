define venv::venv (
  $path,
  $requirements,
  $options,
  $user
) {
  include venv::params

  $packages = $venv::params::packages

  package { $packages :
    ensure => 'installed',
  }

  exec { 'venv-create':
    provider => 'shell',
    command => "virtualenv ${options} ${path}",
    cwd => '/tmp',
    user => $user,
    logoutput => on_failure,
  }

  if $requirements {
    exec { 'venv-requirements':
      provider => 'shell',
      command => "export HOME='/home/${user}' ; . ${path}/bin/activate ; pip install -r ${requirements}",
      cwd => '/tmp',
      user => $user,
      logoutput => on_failure,
    }
  }

  Package[$packages] -> Exec['venv-create'] -> Exec['venv-requirements']
}

