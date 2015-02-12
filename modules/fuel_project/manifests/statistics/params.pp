# default params for fuel_stats
class fuel_project::statistics::params(
  # development parameters
  $development     = false,
  $firewall_enable = false,
  $http_port       = 80,
  $https_port      = 443,
) { }
