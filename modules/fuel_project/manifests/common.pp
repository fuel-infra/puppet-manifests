# Class: fuel_project::common
#
class fuel_project::common (
  $external_host      = false,
  $ldap               = false,
  $ldap_uri           = '',
  $ldap_base          = '',
  $tls_cacertdir      = '',
  $pam_password       = '',
  $pam_filter         = '',
  $sudoers_base       = '',
  $bind_policy        = '',
  $ldap_ignore_users  = '',
  $root_password_hash = 'r00tme',
  $root_shell         = '/bin/bash',
  $facts              = {
    'location' => $::location,
    'role'     => $::role,
  },
) {
  class { '::fuel_project::apps::firewall' :}
  class { '::ntp' :}
  class { '::puppet::agent' :}
  class { '::ssh::authorized_keys' :}
  class { '::ssh::sshd' :
    apply_firewall_rules => $external_host,
  }
  # TODO: remove ::system module
  # ... by spliting it's functions to separate modules
  # or reusing publically available ones
  class { '::system' :}
  class { '::zabbix::agent' :
    apply_firewall_rules => $external_host,
  }

  ::puppet::facter { 'facts' :
    facts => $facts,
  }

  ensure_packages(['tmux', 'screen'])

  if($ldap) {
    class { '::ssh::ldap' :}

    file { '/usr/local/bin/ldap2sshkeys.sh' :
      ensure  => 'present',
      mode    => '0700',
      owner   => 'root',
      group   => 'root',
      content => template('fuel_project/common/ldap2sshkeys.sh.erb'),
    }

    exec { 'sync-ssh-keys' :
      command   => '/usr/local/bin/ldap2sshkeys.sh',
      logoutput => on_failure,
      require   => File['/usr/local/bin/ldap2sshkeys.sh'],
    }

    cron { 'ldap2sshkeys' :
      command => "/usr/local/bin/ldap2sshkeys.sh ${::hostname} 2>&1 | logger -t ldap2sshkeys",
      user    => root,
      hour    => '*',
      minute  => 0,
      require => File['/usr/local/bin/ldap2sshkeys.sh'],
    }
  }

  case $::osfamily {
    'Debian': {
      class { '::apt' :}
    }
    'RedHat': {
      class { '::yum' :}
    }
    default: { }
  }

  zabbix::item { 'software-zabbix-check' :
    template => 'fuel_project/common/zabbix/software.conf.erb',
  }

  # Zabbix hardware item
  ensure_packages(['smartmontools'])

  ::zabbix::item { 'hardware-zabbix-check' :
    content => 'puppet:///modules/fuel_project/common/zabbix/hardware.conf',
    require => Package['smartmontools'],
  }
  # /Zabbix hardware item

  # Zabbix SSL item
  file { '/usr/local/bin/zabbix_check_certificate.sh' :
    ensure => 'present',
    mode   => '0755',
    source => 'puppet:///modules/fuel_project/zabbix/zabbix_check_certificate.sh',
  }
  ::zabbix::item { 'ssl-certificate-check' :
    content => 'puppet:///modules/fuel_project/common/zabbix/ssl-certificate-check.conf',
    require => File['/usr/local/bin/zabbix_check_certificate.sh'],
  }
  # /Zabbix SSL item

  mount { '/' :
    ensure  => 'present',
    options => 'defaults,errors=remount-ro,noatime,nodiratime,barrier=0',
  }

  file { '/etc/hostname' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $::fqdn,
    notify  => Exec['/bin/hostname -F /etc/hostname'],
  }

  file { '/etc/hosts' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('fuel_project/common/hosts.erb'),
  }

  exec { '/bin/hostname -F /etc/hostname' :
    subscribe   => File['/etc/hostname'],
    refreshonly => true,
    require     => File['/etc/hostname'],
  }
}
