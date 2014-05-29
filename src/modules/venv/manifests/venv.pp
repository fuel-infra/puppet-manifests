define venv::venv (
  $path,
  $requirements,
  $options,
  $user
) {
  include venv::params

  include packages
  $packages = $venv::params::packages

  realize Package[$packages]

  exec { 'venv-create':
    command => "virtualenv ${options} ${path}",
    user => $user,
    logoutput => on_failure,
  }

  if $requirements {
    exec { 'venv-requirements':
      command => "export HOME='/home/${user}' ; . ${path}/bin/activate ; pip install -r ${requirements}",
      user => $user,
      cwd => $path,
      logoutput => on_failure,
    }
  }

  Package[$packages]->
    Exec['venv-create']->
    Exec['venv-requirements']
}
