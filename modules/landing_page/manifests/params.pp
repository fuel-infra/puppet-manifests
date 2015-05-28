# Class: landing_page::params
#
class landing_page::params {
  # Landing page webapp
  $app_user               = 'release'
  $apps                   = [
    'landing_page',
    'plugins_catalog',
    'security',
    'sheet'
  ]
  $apply_firewall_rules   = false
  $config                 = '/etc/landing_page/settings.py'
  $config_template        = 'landing_page/landing_page.py.erb'
  $database_engine        = 'django.db.backends.mysql'
  $database_host          = 'localhost'
  $database_name          = 'release'
  $database_password      = 'release'
  $database_port          = ''
  $database_user          = 'release'
  $debug                  = false
  $firewall_allow_sources = {}
  $nginx_access_log       = '/var/log/nginx/access.log'
  $nginx_error_log        = '/var/log/nginx/error.log'
  $nginx_log_format       = undef
  $nginx_server_aliases   = []
  $nginx_server_name      = $::fqdn
  $package                = [
    'landing-page-all',
    'python-mysqldb',
  ]
  $package_updater        = [
    'landing-page-release-status-app-cli',
  ]
  $plugins_repository     = 'http://127.0.0.1'
  $ssl                    = true
  $ssl_cert_file          = '/etc/ssl/release.crt'
  $ssl_cert_file_contents = undef
  $ssl_key_file           = '/etc/ssl/release.pem'
  $ssl_key_file_contents  = undef
  $timezone               = 'UTC'
  $uwsgi_socket           = '127.0.0.1:7939'

  # Updater app
  $updater_app            = 'release'
  $updater_config         = '/etc/release-updater.yaml'
  $updater_token          = '<SECRET_TOKEN>'
  $updater_user           = 'jenkins'
}
