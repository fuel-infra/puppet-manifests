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
    'rack' => [
      'uwsgi-plugin-rack-ruby1.9.1',
      'ruby-rack',
    ]
  }

  $somaxconn      = 65535
}
