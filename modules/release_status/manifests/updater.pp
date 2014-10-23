# Class: release_status::updater
#
class release_status::updater (
  $package = $::release_status::params::package_updater,
  $server_name = $::release_status::params::nginx_server_name,
  $updater_user = $::release_status::params::updater_user,
  $updater_app = $::release_status::params::updater_app,
  $updater_config = $::release_status::params::updater_config,
  $updater_token = $::release_status::params::updater_token,
) inherits ::release_status::params {

  # installing required $packages
  ensure_packages($package)

  # /etc/release-updater.yaml
  # release_updater main configuration file
  file { $updater_config :
    ensure  => 'present',
    mode    => '0400',
    owner   => $updater_user,
    group   => $updater_user,
    content => template('release_status/release_updater.yaml.erb'),
    require => Package[$package],
  }

}
