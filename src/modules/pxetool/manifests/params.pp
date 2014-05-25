class pxetool::params {
  $config = '/etc/pxetool.py'

  $packages = [
    'python-django-pxetool',
  ]

  if $::fqdn =~ /kha\.mirantis\.net$/ {
    # Kharkov internal mirror
    $mirror = 'mirrors.kha.mirantis.net'
  }
  elsif $::fqdn =~ /srt\.mirantis\.net$/ {
    # Saratov internal mirror
    $mirror = 'mirrors.srt.mirantis.net'
  } else {
    # Use Moscow mirror otherwise
    $mirror = 'mirrors.msk.mirantis.net'
  }

  $additional_repos = [
    'deb http://osci-obs.vm.mirantis.net:82/qa-ubuntu/ubuntu/ /',
  ]
}
