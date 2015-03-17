#VMWare Workstation lab
class tpi::vmware_lab (
  $vmware_ws_installer = 'VMware-Workstation-Full-10.0.2-1744117.x86_64.bundle',
  $vmware_ws_serial = '',
  $vmware_ws_envs = [ 'vsphere', 'nsx' ],
  $rsync_server = '172.18.170.69',
) {

  $vmware_packages=[
    'libxtst6',
    'libxcursor1',
  ]

  ensure_packages($vmware_packages)

  $vmware_shared_home='/var/lib/vmware/Shared VMs'

  file { [ '/var/lib/vmware', $vmware_shared_home ]:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  rsync::get { '/etc/vmware/':
    source    => "rsync://${rsync_server}/storage/vmware-envs/config/vmware/",
    purge     => false,
    recursive => true,
    options   => '-aS',
    onlyif    => '! pgrep vmware-vmx',
  }

  $vmware_env_sources=suffix(prefix($vmware_ws_envs,"rsync://${rsync_server}/storage/vmware-envs/"),'/')
  $rsync_source = join($vmware_env_sources, ' ')

  rsync::get { "'${vmware_shared_home}'" :
    source    => $rsync_source,
    purge     => true,
    recursive => true,
    options   => '-aS',
    require   => File[$vmware_shared_home],
    onlyif    => '! pgrep vmware-vmx',
  }

  validate_re(
    $vmware_ws_serial,
    '^[A-Z0-9][A-Z0-9\-]*[A-Z0-9]$',
    'VMWare Workstation serial is invalid'
  )

  exec { 'install_vmware_workstation':
    command => "echo | /storage/${vmware_ws_installer}\
    --console --required --eulas-agreed\
    --set-setting vmware-workstation serialNumber ${vmware_ws_serial}",
    creates => '/usr/bin/vmware',
    require => [
      Class['::tpi::nfs_client'],
      Rsync::Get['/etc/vmware/'],
      Rsync::Get["'${vmware_shared_home}'"]
    ]
  }

  service { 'vmware':
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    pattern   => 'vmware-authdlauncher',
    require   => Exec['install_vmware_workstation'],
  }

  service { 'vmware-workstation-server':
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    pattern   => 'vmware-hostd',
    require   => Exec['install_vmware_workstation'],
  }

  service { 'vmware-USBArbitrator':
    ensure    => 'running',
    enable    => true,
    hasstatus => false,
    pattern   => 'vmware-usbarbitrator',
    require   => Exec['install_vmware_workstation'],
  }

}
