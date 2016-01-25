# Define: venv::exec
#
# This definition provides exec command interface inside defined environment.
# Provides all exec functionalities (like cwd and onlyif).
#
# Parameters:
#
#   [*command*] - command to run under venv
#   [*venv*] - venv path to use
#   [*cwd*] - working directory
#   [*onlyif*] - run only if this command returns 0
#   [*user*] - user to run this command
#

define venv::exec (
  $command,
  $venv,
  $cwd    = '/tmp',
  $onlyif = '/bin/true',
  $user   = 'nobody',
) {

  ensure_packages(['python-virtualenv'])

  exec { "${user}@${venv}:${cwd} exec ${command}" :
    command   => "HOME='/home/${user}' ; \
      . ${venv}/bin/activate ; ${command}",
    user      => $user,
    cwd       => $cwd,
    logoutput => on_failure,
    onlyif    => $onlyif,
  }
}
