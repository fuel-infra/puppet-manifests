# Class: uwsgi::params
#
class uwsgi::params {
  $service = 'uwsgi'
  $packages = [
    'uwsgi',
    'uwsgi-plugin-python',
  ]
}
