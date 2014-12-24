# Class: fuel_project::landing_page
#
class fuel_project::landing_page (
  $packages = ['landing-page-meta'],
  $landing_service_name = ['fuel-infra.org', 'www.fuel-infra.org', "landing.${::fqdn}"],
  $static_service_name = ['static.fuel-infra.org', "static.${::fqdn}"],
) {
  ensure_packages($packages)

  ::nginx::resource::vhost { 'landing_page' :
    ensure      => 'present',
    autoindex   => 'off',
    www_root    => '/var/www/landing_page',
    server_name => $landing_service_name,
    require     => Package[$packages],
  }
}
