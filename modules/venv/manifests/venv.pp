# Define: venv::venv
#
# Defines base for venv environments.
#
# Parameters:
#   [*path*] - path to venv
#   [*options*] - virtualenv options to use
#   [*packages*] - packages required by virtualenv
#   [*pip_opts*] - additional pip command options
#   [*requirements*] - file with venv requirements
#   [*user*] - user to run virtualenv command
#
define venv::venv (
  $path,
  $options      = '',
  $packages     = [],
  $pip_opts     = '',
  $requirements = '',
  $user         = 'root',
) {


  $venv_packages = [
    'git',
    'python-dev',
    'python-virtualenv',
  ]

  ensure_packages($venv_packages)
  ensure_packages($packages)

  exec { "virtualenv ${options} ${path}" :
    command   => "virtualenv ${options} ${path}",
    creates   => $path,
    user      => $user,
    logoutput => on_failure,
    require   => [
      Package['python-virtualenv'],
    ],
  }

  if $requirements {
    exec { ". ${path}/bin/activate ; pip install -r ${requirements}" :
      command   => "export HOME='/home/${user}' ; \
        . ${path}/bin/activate ; pip install ${pip_opts} -r ${requirements}",
      user      => $user,
      cwd       => $path,
      logoutput => on_failure,
      require   => [
        Exec["virtualenv ${options} ${path}"],
        Package[$packages],
      ],
    }
  }
}
