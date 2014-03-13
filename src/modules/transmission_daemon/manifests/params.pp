class transmission_daemon::params {
  $config = '/etc/transmission-daemon/settings.json'
  $packages = [
    'transmission-daemon'
  ]
  $service = 'transmission-daemon'
}
