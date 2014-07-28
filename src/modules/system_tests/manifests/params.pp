class system_tests::params {
  $packages = [
    # dependencies
    'libevent-dev',
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

    # diagnostic utilities
    'htop',
    'sysstat',
    'dstat',
    'vncviewer',
  ]
  $sudo_commands = ['/sbin/ebtables']
  $workspace = '/home/jenkins/workspace'
}
