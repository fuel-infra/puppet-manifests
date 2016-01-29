# Class: fuel_project::mongo_common
#
# This class deploys MongoDB common parts.
#
# Parameters:
#   [*primary*] - enable primary role
#

class fuel_project::mongo_common (
  $primary = false,
)
{
  if $primary {
    class { '::fuel_project::common' :} ->
    class {'::mongodb::client': } ->
    class {'::mongodb::server': } ->
    class {'::mongodb::replset': } ->
    class {'::fuel_project::mongodb': }
  } else {
    class { '::fuel_project::common' :} ->
    class {'::mongodb::client': } ->
    class {'::mongodb::server': }
  }
}
