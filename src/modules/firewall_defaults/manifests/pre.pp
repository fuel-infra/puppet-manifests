class firewall_defaults::pre {
  if $external_host {
    package { 'iptables-persistent' :
      ensure => installed,
    }->
    resources { "firewall" :
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
}
