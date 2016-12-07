# Class: uwsgi::params
#
# This class contains default values for uwsgi classes.
#
class uwsgi::params {
  $package = 'uwsgi'
  $service = 'uwsgi'

  # Plugins
  $plugins_packages = {
    'python' => [
      'uwsgi-plugin-python',
    ],
    'python3' => [
      'uwsgi-plugin-python3',
    ],
    'rack' => [
      'uwsgi-plugin-rack-ruby1.9.1',
      'ruby-rack',
    ]
  }

  $somaxconn      = 65535
}
