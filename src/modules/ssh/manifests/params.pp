class ssh::params {
  $packages = [
    'openssh-server'
  ]

  $ldap_packages = [
    'ldap-utils',
    'libpam-ldap',
    'nscd',
  ]

  $service = 'ssh'

  $sshd_config = '/etc/ssh/sshd_config'
}
