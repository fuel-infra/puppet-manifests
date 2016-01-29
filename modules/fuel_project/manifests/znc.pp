# Class: fuel_project::znc
#
# This class enables ZNC instance.
#
# Parameters:
#   [*apply_firewall_rules*] - apply embedded firewall rules
#   [*service_port*] - service port
#
class fuel_project::znc (
  $apply_firewall_rules = false,
  $service_port = 7777,
){
  class { '::fuel_project::common':
    external_host => $apply_firewall_rules,
  }

  class { '::znc': port => $service_port}

  if $apply_firewall_rules {
    include firewall_defaults::pre
    firewall { '1000 Allow znc connection' :
      ensure  => present,
      dport   => $service_port,
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }

}