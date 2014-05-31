class pxetool::params {
  # configuration files
  $config = '/etc/pxetool.py'
  $nginx_conf = '/etc/nginx/sites-available/pxetool.conf'
  $nginx_conf_link = '/etc/nginx/sites-enabled/pxetool.conf'

  # dependencies are on packages
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

  # repositories to add on setup with pxetool
  $additional_repos = [
    'deb http://osci-obs.vm.mirantis.net:82/qa-ubuntu/ubuntu/ /',
  ]
}
