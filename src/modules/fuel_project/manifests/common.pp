# Class: fuel_project::common
#
class fuel_project::common (
  $external_host     = false,
  $ldap              = false,
  $ldap_uri          = '',
  $ldap_base         = '',
  $tls_cacertdir     = '',
  $pam_password      = '',
  $pam_filter        = '',
  $sudoers_base      = '',
  $bind_policy       = '',
  $ldap_ignore_users = '',
) {
  include dpkg
  include firewall_defaults::pre
  include firewall_defaults::post
  class { '::ntp':
    servers  => ['pool.ntp.org'],
    restrict => ['127.0.0.1'],
  }
  include puppet::agent
  include ssh::authorized_keys
  include ssh::sshd
  include system

  $zabbix = hiera_hash('zabbix')

  if $external_host {
    $firewall = hiera_hash('firewall')

    class { 'zabbix::agent' :
      zabbix_server          => $zabbix['server_external'],
      server_active          => false,
      enable_firewall        => true,
      firewall_allow_sources => $firewall['known_networks']
    }
  } else {
    class { 'zabbix::agent' :
      zabbix_server => $zabbix['server'],
      server_active => $zabbix['server'],
    }
  }

  if($ldap) {
    class { 'ssh::ldap' :
      ldap_uri          => $ldap_uri,
      ldap_base         => $ldap_base,
      tls_cacertdir     => $tls_cacertdir,
      pam_password      => $pam_password,
      pam_filter        => $pam_filter,
      sudoers_base      => $sudoers_base,
      bind_policy       => $bind_policy,
      ldap_ignore_users => $ldap_ignore_users,
    }
  }
}
