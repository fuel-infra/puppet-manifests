# Define: venv::exec
# This class provides exec command interface inside defined environment.
# Provides all exec functionalities (like cwd and onlyif).

define venv::exec (
  $command,
  $venv,
  $cwd = '/tmp',
  $user = 'nobody',
  $onlyif = '/bin/true',
) {

  if (!defined(Package['python-virtualenv'])) {
    package { 'python-virtualenv' :
      ensure => 'present',
    }
  }

  exec { $command:
    command   => "HOME='/home/${user}' ; \
      . ${venv}/bin/activate ; ${command}",
    user      => $user,
    cwd       => $cwd,
    logoutput => on_failure,
    onlyif    => $onlyif,
  }
}
