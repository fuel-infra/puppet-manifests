# Class: landing_page::params
#
class landing_page::params {
  $apply_firewall_rules = false
  $config = '/etc/landing_page/settings.py'
  $config_template = 'landing_page/landing_page.py.erb'
  $firewall_allow_sources = {}
  $mysql_database = 'release'
  $mysql_user = 'release'
  $mysql_password = 'pass'
  $mysql_host = '127.0.0.1'
  $mysql_port = 3306
  $nginx_server_name = $::fqdn
  $app_user = 'release'
  $package = [
    'landing-page-all',
    'python-mysqldb',
  ]
  $package_updater = ['landing-page-release-status-app-cli']
  $ssl_cert_file = '/etc/ssl/release.crt'
  $ssl_key_file = '/etc/ssl/release.pem'
  $timezone = 'UTC'
  $updater_user = 'jenkins'
  $updater_app = 'release'
  $updater_config = '/etc/release-updater.yaml'
  $updater_token = 'b3ccf1131c697f26be216753ddac28ca19f05035fbe914968ee7b7c32e274c94c58b3b266e83967093fc52e0527db86e7e92b9b51683b082c08b90c1af552029'
}
