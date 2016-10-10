# Class: fuel_project::jenkins::slave
#
# This class deploys full Jenkins slave node with all the requirements.
#
# Parameters:
#   [*bats_tests*] - enable bats tests
#   [*build_fuel_iso*] - Boolean, Flag to turn on ISO building capabilities
#     Refer to ::fuel_project::jenkins::slave::iso_build for more details.
#   [*build_fuel_plugins*] - install packages fpr fuel-plugins
#   [*check_tasks_graph*] - install tasks graph requirements
#   [*fuel_web_selenium*] - install packages for selenium tests
#   [*run_k8s*] - dependencies to run k8s
#   [*run_tests*] - dependencies to run tests
#   [*simple_syntax_check*] - add syntax check tools
#   [*verify_fuel_astute*] - add fuel_astute verification requirements
#   [*verify_fuel_docs*] - add fuel_docs verification requirements
#   [*verify_fuel_pkgs_requirements*] - add fuel_pkgs verification requirements
#   [*verify_fuel_stats*] - add fuel_status verification requirements
#   [*verify_fuel_web*] - add fuel_web verification requirements
#   [*verify_fuel_web_npm_packages*] - add fuel_web npm packages requirements
#   [*verify_jenkins_jobs*] - add jenkins_jobs verification requirements
#   [*verify_network_checker*] - add network checker verification requirements
#
class fuel_project::jenkins::slave (
  $bats_tests                           = false,
  $build_fuel_iso                       = false,
  $build_fuel_plugins                   = false,
  $check_tasks_graph                    = false,
  $fuel_web_selenium                    = false,
  $run_k8s                              = false,
  $run_tests                            = false,
  $simple_syntax_check                  = false,
  $verify_fuel_astute                   = false,
  $verify_fuel_docs                     = false,
  $verify_fuel_pkgs_requirements        = false,
  $verify_fuel_stats                    = false,
  $verify_fuel_web                      = false,
  $verify_jenkins_jobs                  = false,
  $verify_network_checker               = false,
  $x11_display_num                      = 99,
) {
  if($::osfamily == 'RedHat') {
    include ::selinux
  }

  include ::devopslib::downloads_cleaner
  include ::fuel_project::common
  include ::jenkins::slave
  include ::transmission::daemon

  # Partial compability layer {
  if($build_fuel_iso) {
    include ::fuel_project::jenkins::slave::iso_build
  }

  if($bats_tests) {
    include ::fuel_project::jenkins::slave::bats_tests
  }

  if ($build_fuel_plugins) {
    include ::fuel_project::jenkins::slave::build_fuel_plugins
  }

  if ($verify_fuel_docs) {
    include ::fuel_project::jenkins::slave::verify_fuel_docs
  }

  if ($verify_jenkins_jobs) {
    include ::fuel_project::jenkins::slave::verify_jenkins_jobs
  }

  if ($verify_fuel_astute) {
    include ::fuel_project::jenkins::slave::verify_fuel_astute
  }

  if ($verify_network_checker) {
    include ::fuel_project::jenkins::slave::verify_network_checker
  }

  if ($simple_syntax_check) {
    include ::fuel_project::jenkins::slave::simple_syntax_check
  }

  if ($check_tasks_graph){
    include ::fuel_project::jenkins::slave::check_tasks_graph
  }

  if ($verify_fuel_pkgs_requirements){
    include ::fuel_project::jenkins::slave::verify_fuel_pkgs_requirements
  }

  if ($run_tests) {
    include ::fuel_project::jenkins::slave::run_tests
  }

  if ($osci_test) {
    include ::fuel_project::jenkins::slave::osci_test
  }

  if ($verify_fuel_stats) {
    include ::fuel_stats::tests
  }

  if ($verify_fuel_web) {
    include ::fuel_project::jenkins::slave::verify_fuel_web
  }

  if ($run_k8s) {
    include ::fuel_project::jenkins::slave::run_k8s
  }
  # } Partial compability layer

  case $::osfamily {
    'Debian': {
      $packages = [
        'dutop',
        'python-git',
        'python-pip',
        'python-seed-client',
        'python-tox',
        'python-yaml',
        'sqlite3',
      ]
    }
    'RedHat': {
      $packages = [
        'gitpython',
        'PyYAML',
        'sqlite',
      ]
    }
    default: {
      $packages = []
    }
  }

  ensure_packages($packages)

  file { '/home/jenkins' :
    ensure  => 'directory',
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/home/jenkins/.ssh' :
    ensure  => 'directory',
    mode    => '0700',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }


  if ($local_ssh_private_key) {
    file { '/home/jenkins/.ssh/id_rsa' :
      ensure  => 'present',
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $local_ssh_private_key,
      require => [
        User['jenkins'],
        File['/home/jenkins/.ssh'],
      ]
    }
  }

  if ($local_ssh_public_key) {
    file { '/home/jenkins/.ssh/id_rsa.pub' :
      ensure  => 'present',
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $local_ssh_public_key,
      require => [
        User['jenkins'],
        File['/home/jenkins/.ssh'],
      ]
    }
  }

  # FIXME: Legacy compability LP #1418927
  cron { 'devops-env-cleanup' :
    ensure => 'absent',
  }
  file { '/usr/local/bin/devops-env-cleanup.sh' :
    ensure => 'absent',
  }
  file { '/etc/devops/local_settings.py' :
    ensure => 'absent',
  }
  file { '/etc/devops' :
    ensure  => 'absent',
    force   => true,
    require => File['/etc/devops/local_settings.py'],
  }
  package { 'python-devops' :
    ensure            => 'absent',
    uninstall_options => ['purge']
  }
  # /FIXME
}
