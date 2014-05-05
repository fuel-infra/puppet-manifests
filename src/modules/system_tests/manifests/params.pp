class system_tests::params {
  $packages = [
    'python-anyjson',
    'python-devops',
    'python-glanceclient',
    'python-ipaddr',
    'python-keystoneclient',
    'python-novaclient',
    'python-paramiko',
    'python-proboscis',
    'python-seed-cleaner',
    'python-seed-client',
    'python-xmlbuilder',
    'python-yaml',
  ]
  $sudo_commands = ['/sbin/ebtables']
  $workspace = '/home/jenkins/workspace'
}
