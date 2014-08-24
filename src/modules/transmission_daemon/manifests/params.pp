# Class: transmission_daemon::params
#
class transmission_daemon::params {
  $config = '/etc/transmission-daemon/settings.json'
  $download_dir = '/srv/downloads'
  $packages = [
    'transmission-daemon'
  ]
  $service = 'transmission-daemon'
  $utp_enabled = false
}
