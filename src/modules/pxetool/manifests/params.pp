# Class: pxetool::params
#
class pxetool::params {
  $additional_repos = []
  $apply_firewall_rules = false
  $config = '/etc/pxetool.py'
  $disk_pattern = '(\/dev\/sd([a-z]+)|\/dev\/(x)?vd([a-z]+))'
  $firewall_allow_sources = {}
  $mirror = 'archive.ubuntu.com'
  $nginx_conf = '/etc/nginx/sites-available/pxetool.conf'
  $nginx_conf_link = '/etc/nginx/sites-enabled/pxetool.conf'
  $package = 'python-django-pxetool'
  $puppet_master = $::fqdn
  $root_password_hash = ''
  $service_port = 80
  $timezone = 'UTC'
}
