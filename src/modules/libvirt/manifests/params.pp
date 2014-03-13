class libvirt::params {
  $packages = [
    'libvirt-bin',
    'python-libvirt',
    'qemu-kvm',
  ]
  $service = 'libvirt-bin'
  $config = '/etc/libvirt/libvirtd.conf'
  $default_config = '/etc/default/libvirt-bin'
}
