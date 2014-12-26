# Class: landing_page::updater
#
class landing_page::updater (
  $package = $::landing_page::params::package_updater,
  $server_name = $::landing_page::params::nginx_server_name,
  $user = $::landing_page::params::updater_user,
  $application = $::landing_page::params::updater_app,
  $config = $::landing_page::params::updater_config,
  $token = $::landing_page::params::updater_token,
) inherits ::landing_page::params {

  # installing required $packages
  ensure_packages($package)

  # /etc/release-updater.yaml
  # release_updater main configuration file
  file { $config :
    ensure  => 'present',
    mode    => '0400',
    owner   => $user,
    group   => $user,
    content => template('landing_page/release_updater.yaml.erb'),
    require => Package[$package],
  }

}
