# default params for fuel_stats
class fuel_project::statistics::params(
  # development parameters
  $development            = false,

  $firewall_enable        = false,

  $service_port           = undef,
) { }
