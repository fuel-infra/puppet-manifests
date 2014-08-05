class libvirt::params {
  $packages = [
    'libvirt-bin',
    'python-libvirt',
    'qemu-kvm',
  ]
  $service = 'libvirt-bin'
  $config = '/etc/libvirt/libvirtd.conf'
  $default_config = '/etc/default/libvirt-bin'
  $default_pool_dir = '/var/lib/libvirt/images'
  $default_pool_name = 'default'

  if $external_host {
    $listen_addr = '127.0.0.1'
  } else {
    $listen_addr = '0.0.0.0'
  }
}
