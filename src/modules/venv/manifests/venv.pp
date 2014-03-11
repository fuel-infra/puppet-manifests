define venv::venv (
  $path,
  $requirements,
  $options,
  $user
) {
  exec { 'venv-create':
    provider => 'shell',
    command => "virtualenv ${options} ${path}",
    cwd => '/tmp',
    user => $user,
  }

  if $requirements {
    exec { 'venv-requirements':
      provider => 'shell',
      command => ". ${path}/bin/activate ; pip install -r ${requirements}",
      cwd => '/tmp',
      user => $user,
    }
  }

  Exec['venv-create'] -> Exec['venv-requirements']
}

