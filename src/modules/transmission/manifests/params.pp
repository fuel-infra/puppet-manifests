# Class: transmission::params
#
class transmission::params {
  $config = '/etc/transmission-daemon/settings.json'
  $packages = [
    'transmission-daemon'
  ]
  $service = 'transmission-daemon'
}
