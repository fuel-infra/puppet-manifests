# Class: ssh::ldap
#
class ssh::ldap (
  $ldap_uri = '',
  $ldap_base = '',
  $tls_cacertdir = '',
  $pam_password = $ssh::params::pam_password,
  $pam_filter = '',
  $sudoers_base = '',
  $bind_policy = $ssh::params::bind_policy,
  $ldap_ignore_users = $ssh::params::ldap_ignore_users
) {
  include ssh::params

  include ssh::banner
  include ssh::sshd

  $ldap_packages = $ssh::params::ldap_packages

  package { $ldap_packages :
    ensure => 'present',
  }

  file { '/etc/ldap.conf':
    ensure  => 'present',
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
    content => template('ssh/ldap.conf.erb'),
  }

  file { '/etc/ldap/ldap.conf' :
    ensure => 'link',
    target => '/etc/ldap.conf',
  }

  file { '/etc/nsswitch.conf':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('ssh/nsswitch.conf.erb'),
    notify  => Service['nscd'],
  }

  file { '/etc/pam.d/common-session' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('ssh/common-session.erb'),
  }

  service { 'nscd' :
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
  }

  Class['ssh::sshd']->
    Package[$ldap_packages]->
    File['/etc/ldap.conf']->
    File['/etc/ldap/ldap.conf']->
    File['/etc/nsswitch.conf']->
    File['/etc/pam.d/common-session']->
    Service['nscd']
}
