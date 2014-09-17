# Class: ssh::params
#
class ssh::params {
  $apply_firewall_rules = false
  $firewall_allow_sources = {}
  $bind_policy = 'soft'
  $ldap_ignore_users = 'backup,bin,daemon,games,gnats,irc,landscape,libuuid,list,lp,mail,man,messagebus,mysql,nagios,news,ntp,postfix,proxy,puppet,root,sshd,sync,sys,syslog,uucp,whoopsie,www-data,zabbix'
  $pam_password = 'md5'

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
