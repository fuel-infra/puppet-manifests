# Class: fuel_project::jenkins::master
#
class fuel_project::jenkins::master (
  $firewall_enable = false,
) {
  class { '::fuel_project::common':
    external_host => $firewall_enable,
  }
  class { '::jenkins::master':
    apply_firewall_rules => $firewall_enable,
  }
}

