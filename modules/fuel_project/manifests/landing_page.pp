# Class: fuel_project::landing_page
#
class fuel_project::landing_page (
  $landing_service_name = ['fuel-infra.org', 'www.fuel-infra.org', "landing.${::fqdn}"],
  $static_service_name = ['static.fuel-infra.org', "static.${::fqdn}"],

) {
  class { '::landing_page' :}
}
