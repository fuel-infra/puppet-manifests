# == Class venv::init
#
class venv {
  venv::venv { 'venv-nailgun-tests' :
    path         => '/home/jenkins/venv-nailgun-tests',
    requirements => 'https://raw.github.com/stackforge/fuel-main/master/fuelweb_test/requirements.txt',
    options      => '--system-site-packages',
    user         => 'jenkins',
  }
}
