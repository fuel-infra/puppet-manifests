# Class: transmission::params
#
# This class defines default variables used by used by daemon class.
#
# Parameters:
#   [*config*] - path to transmission config files
#   [*packages*] - transmission daemon packages
#   [*service*] - transmission service name
#
class transmission::params {
  $config   = '/etc/transmission-daemon/settings.json'
  $packages = [
    'transmission-daemon'
  ]
  $service  = 'transmission-daemon'
}
