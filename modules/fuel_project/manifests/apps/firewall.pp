# Class: fuel_project::apps::firewall
#
# This is new class which defines firewall from hiera database. Includes
# standard pre and post custom rules.
#
# Hiera parameters:
#   [*rules*] - defines hash with firewall entries
#     Example:
#     '100 - SSH access from New York Office':
#       source: '11.22.33.44/23'
#       dport: 22
#       proto: 'tcp'
#       action: 'accept'
#
class fuel_project::apps::firewall {
  $rules = hiera_hash('fuel_project::apps::firewall::rules', undef)

  if ($rules) {
    case $::osfamily {
      'Debian': {
        package { 'iptables-persistent' :
          ensure => 'present',
          before => Resources['firewall']
        }
      }
      default: { }
    }

    resources { 'firewall' :
      purge => true,
    }

    firewall { '0000 - accept all icmp' :
      proto   => 'icmp',
      action  => 'accept',
      require => undef,
    }->
    firewall { '0001 - accept all to lo interface' :
      proto   => 'all',
      iniface => 'lo',
      action  => 'accept',
    }->
    firewall { '0002 - accept related established rules' :
      proto   => 'all',
      ctstate => ['RELATED', 'ESTABLISHED'],
      action  => 'accept',
    }

    firewall { '0000 - accept all ICMPv6 traffic' :
      proto    => 'ipv6-icmp',
      action   => 'accept',
      require  => undef,
      provider => 'ip6tables'
    }->
    firewall { '0001 - accept all IPv6 traffic to lo interface' :
      proto    => 'all',
      iniface  => 'lo',
      action   => 'accept',
      provider => 'ip6tables',
    }->
    firewall { '0002 - accept related established rules for IPv6' :
      proto    => 'all',
      ctstate  => ['RELATED', 'ESTABLISHED'],
      action   => 'accept',
      provider => 'ip6tables',
    }

    create_resources(firewall, $rules, {
      before  => Firewall['9999 - drop all'],
      require => [
        Firewall['0000 - accept all icmp'],
        Firewall['0001 - accept all to lo interface'],
        Firewall['0002 - accept related established rules'],
        Firewall['0000 - accept all ICMPv6 traffic'],
        Firewall['0001 - accept all IPv6 traffic to lo interface'],
        Firewall['0002 - accept related established rules for IPv6'],
      ]
    })

    firewall { '9999 - drop all' :
      proto  => 'all',
      action => 'drop',
      before => undef,
    }
    firewall { '9999 - drop all IPv6' :
      proto    => 'all',
      action   => 'drop',
      before   => undef,
      provider => 'ip6tables',
    }
  }
}
