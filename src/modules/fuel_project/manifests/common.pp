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
  $puppet = hiera_hash('puppet')
  $zabbix = hiera_hash('zabbix')

  class { '::ntp' :}
  class { '::puppet::agent' :}
  class { '::ssh::authorized_keys' :}
  class { '::ssh::sshd' :
    apply_firewall_rules => $external_host,
  }
  include ::system

  if $external_host {
    class { '::zabbix::agent' :
      zabbix_server        => $zabbix['server_external'],
      server_active        => false,
      apply_firewall_rules => true,
    }
  } else {
    class { '::zabbix::agent' :
      zabbix_server => $zabbix['server'],
      server_active => $zabbix['server'],
    }
  }

  if (!defined(Package['tmux'])) {
    package { 'tmux' :
      ensure => 'present',
    }
  }

  if (!defined(Package['screen'])) {
    package{ 'screen' :
      ensure => 'present',
    }
  }

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

  class { '::apt' :
    always_apt_update    => true,
    disable_keys         => false,
    purge_sources_list   => true,
    purge_sources_list_d => true,
    purge_preferences_d  => true,
    update_timeout       => 300,
  }

  zabbix::item { 'sofware-zabbix-check' :
    content => 'puppet:///modules/fuel_project/common/zabbix/software.conf',
  }

  zabbix::item { 'hardware-zabbix-check' :
    content => 'puppet:///modules/fuel_project/common/zabbix/hardware.conf',
  }
}
