# Class: fuel_project::jenkins::slave::osci_test
#
# Class setup old OSCI requirements.
#
class fuel_project::jenkins::slave::osci_test (
  $osc_apiurl                          = '',
  $osc_pass_primary                    = '',
  $osc_pass_secondary                  = '',
  $osc_url_primary                     = '',
  $osc_url_secondary                   = '',
  $osc_user_primary                    = '',
  $osc_user_secondary                  = '',
  $osci_obs_jenkins_key                = '',
  $osci_obs_jenkins_key_contents       = '',
  $osci_vm_centos_jenkins_key          = '',
  $osci_vm_centos_jenkins_key_contents = '',
  $osci_vm_trusty_jenkins_key          = '',
  $osci_vm_trusty_jenkins_key_contents = '',
  $osci_vm_ubuntu_jenkins_key          = '',
  $osci_vm_ubuntu_jenkins_key_contents = '',
  $target_dirs                         = [
    '/home/jenkins/vm-centos-test-rpm',
    '/home/jenkins/vm-ubuntu-test-deb',
    '/home/jenkins/vm-trusty-test-deb',
  ],
) {
  include ::fuel_project::jenkins::slave::run_tests

  $packages = [
    'osc',
    'yum-utils',
  ]

  ensure_packages($packages)

  file { 'oscrc' :
    path    => '/home/jenkins/.oscrc',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    content => template('fuel_project/jenkins/slave/oscrc.erb'),
    require => [
      Package[$packages],
      User['jenkins'],
    ],
  }

  # osci needed directories
  file { $target_dirs :
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  # osci needed ssh keys
  file {
      [
        $osci_obs_jenkins_key,
        $osci_vm_ubuntu_jenkins_key,
        $osci_vm_centos_jenkins_key,
        $osci_vm_trusty_jenkins_key
      ]:
    owner   => 'jenkins',
    group   => 'nogroup',
    mode    => '0600',
    content => [
      $osci_obs_jenkins_key_contents,
      $osci_vm_ubuntu_jenkins_key_contents,
      $osci_vm_centos_jenkins_key_contents,
      $osci_vm_trusty_jenkins_key_contents
    ],
    require => [
      File[concat(['/home/jenkins/.ssh'], $target_dirs)],
      User['jenkins'],
    ],
  }
}
