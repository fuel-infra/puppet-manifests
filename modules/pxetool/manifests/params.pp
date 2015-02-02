# Class: pxetool::params
#
class pxetool::params {
  $additional_repos = []
  $apply_firewall_rules = false
  $config = '/etc/pxetool/settings.py'
  $disk_pattern = '(\/dev\/sd([a-z]+)|\/dev\/(x)?vd([a-z]+))'
  $firewall_allow_sources = {}
  $mirror = 'archive.ubuntu.com'
  $nginx_access_log = '/var/log/nginx/access.log'
  $nginx_conf = '/etc/nginx/sites-available/pxetool.conf'
  $nginx_conf_link = '/etc/nginx/sites-enabled/pxetool.conf'
  $nginx_error_log = '/var/log/nginx/error.log'
  $nginx_log_format = 'proxy'
  $package = 'python-django-pxetool'
  $puppet_master = $::fqdn
  $root_password_hash = ''
  $service_port = 80
  $timezone = 'UTC'
}
