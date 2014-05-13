class seed::params {
  $nginx_conf = '/etc/nginx/sites-available/seed.conf'
  $seed_conf = '/usr/share/python-django-seed/seed/seed/settings.py'
  $uwsgi_conf = '/etc/uwsgi/apps-available/seed.yaml'

  $packages = [
    'uwsgi',
    'uwsgi-plugin-python',
    'python-django-seed',
  ]

  $allowed_ips = [
    '91.218.144.129/32'
  ]
}
