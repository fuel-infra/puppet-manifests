# Class: fuel_project::common
#
class fuel_project::common (
  $external_host = false,
  $ldap          = false,
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
    include ssh::ldap
  }
}
