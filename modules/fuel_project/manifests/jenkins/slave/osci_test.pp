# Class: fuel_project::jenkins::slave::osci_test
#
# Class sets up osci_test role
#
# Parameters:
#   [*osci_ubuntu_job_dir*] =
class fuel_project::jenkins::slave::osci_test (
  $osc_apiurl                          = '',
  $osc_pass_primary                    = '',
  $osc_pass_secondary                  = '',
  $osc_url_primary                     = '',
  $osc_url_secondary                   = '',
  $osc_user_primary                    = '',
  $osc_user_secondary                  = '',
  $osci_obs_jenkins_key                = '',
  $osci_vm_ubuntu_jenkins_key          = '',
  $osci_vm_centos_jenkins_key          = '',
  $osci_vm_trusty_jenkins_key          = '',
  $osci_obs_jenkins_key_contents       = '',
  $osci_vm_ubuntu_jenkins_key_contents = '',
  $osci_vm_centos_jenkins_key_contents = '',
  $osci_vm_trusty_jenkins_key_contents = '',
  $target_dirs                         = [
    '/home/jenkins/vm-centos-test-rpm',
    '/home/jenkins/vm-ubuntu-test-deb',
    '/home/jenkins/vm-trusty-test-deb',
  ],
) {
  $packages = [
    'osc',
    'yum-utils',
  ]

  ensure_packages($packages)

  if($::virtual == 'physical') {
    if($::processor0 =~ /^Intel/) {
      file { '/etc/modprobe.d/qemu-system-x86.conf' :
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options kvm_intel nested=1'
      }
      # load kvm_intel module only if Intel cpu found.
      exec { '/sbin/modprobe kvm_intel' :
        user      => 'root',
        logoutput => 'on_failure',
        require   => File['/etc/modprobe.d/qemu-system-x86.conf'],
      }
    } else {
      warning("qemu-kvm modules was not loaded because processor vendor is not Intel. Don't what to load :(")
    }
  }

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

  # osci kvm settings
  if (!defined(Class['::libvirt'])) {
    class { '::libvirt' :
      mdns_adv           => false,
      unix_sock_rw_perms => '0777',
      qemu               => true,
      defaultnetwork     => true,
    }
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
