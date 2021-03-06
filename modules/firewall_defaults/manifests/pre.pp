# Class: firewall_defaults::pre
#
# Simple class which is run at the beggining of firewall rules. It covers four
# basic tasks:
# - installs persistent firewall
# - accept all the icmp packets
# - allow any traffic on lo interface
# - allow already estabished and related connections
#
class firewall_defaults::pre {
  include firewall_defaults::post

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

  Firewall {
      before  => Class['firewall_defaults::post'],
  }

  firewall { '000 accept all icmp':
    proto   => 'icmp',
    action  => 'accept',
    require => undef,
  }->
  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }->
  firewall { '002 accept related established rules':
    proto   => 'all',
    ctstate => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  }
}
