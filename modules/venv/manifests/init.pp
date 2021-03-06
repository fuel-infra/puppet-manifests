# Class venv::init
#
# This class initialize venv environment for Python.
#
# Parameters:
#
#   [*pip_opts*] - additional pip command options
#   [*requirements*] - file with venv requirements
#
class venv (
  $pip_opts     = '',
  $requirements = 'https://raw.github.com/openstack/fuel-qa/master/fuelweb_test/requirements.txt',
) {
  venv::venv { 'venv-nailgun-tests' :
    path         => '/home/jenkins/venv-nailgun-tests',
    requirements => $requirements,
    options      => '--system-site-packages',
    pip_opts     => $pip_opts,
    user         => 'jenkins',
  }
}
