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
  }

  if $requirements {
    exec { 'venv-requirements':
      provider => 'shell',
      command => ". ${path}/bin/activate ; pip install -r ${requirements}",
      cwd => '/tmp',
      user => $user,
    }
  }

  Package[$packages] -> Exec['venv-create'] -> Exec['venv-requirements']
}

