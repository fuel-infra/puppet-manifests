# Class: fuel_project::common
#
# This class deploys basic requirements for fuel_project classes.
#
# Parameters:
#   [*bind_policy*] - LDAP binding policy
#   [*external_host*] - host deployed on external IP address
#   [*kernel_package*] - kernel package to install
#   [*ldap*] - use LDAP authentication
#   [*ldap_base*] - LDAP base
#   [*ldap_ignore_users*] - users ignored for LDAP checks
#   [*ldap_uri*] - LDAP URI
#   [*logrotate_rules*] - log rotate rules hash
#   [*logstash_forwarder*] - enable logstash forwarder
#   [*pam_filter*] - PAM filter for LDAP
#   [*pam_password*] - PAM password type
#   [*puppet_cron*] - run Puppet agent by cron
#   [*puppet_cron_ok*] - "YES, I KNOW WHAT I AM DOING, REALLY" - to confirm
#   [*root_password_hash*] - root password
#   [*root_shell*] - shell for root user
#   [*tls_cacertdir*] - LDAP CA certs directory
#
class fuel_project::common (
  $bind_policy        = '',
  $external_host      = false,
  $kernel_package     = undef,
  $ldap               = false,
  $ldap_base          = '',
  $ldap_ignore_users  = '',
  $ldap_uri           = '',
  $logrotate_rules    = hiera_hash('logrotate::rules', {}),
  $logstash_forwarder = false,
  $pam_filter         = '',
  $pam_password       = '',
  $puppet_cron        = {},
  $puppet_cron_ok     = '',
  $root_password_hash = 'r00tme',
  $root_shell         = '/bin/bash',
  $tls_cacertdir      = '',
) {
  $facts = hiera_hash('::fuel_project::common::facts', {
    'location' => $::location,
    'role'     => $::role,
  })
  class { '::atop' :}
  if($logstash_forwarder) {
    class { '::log_storage::logstashforwarder' :}
  }
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

  ensure_packages([
    'apparmor',
    'config-zabbix-agent-dmesg-item',
    'config-zabbix-agent-oom-killer-item',
    'config-zabbix-agent-ulimit-item',
    'facter-facts',
    'screen',
    'tmux',
  ])

  # install the exact version of kernel package
  # please note, that reboot must be done manually
  if($kernel_package) {
    ensure_packages($kernel_package)
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
      minute  => fqdn_rand(59),
      require => File['/usr/local/bin/ldap2sshkeys.sh'],
    }
  }

  case $::osfamily {
    'Debian': {
      class { '::apt' :}
    }
    'RedHat': {
      class { '::yum' :}
      $yum_repos_gpgkey = hiera_hash('yum::gpgkey', {})
      create_resources('::yum::gpgkey', $yum_repos_gpgkey)
      class { '::yumrepos' :}
    }
    default: { }
  }

  # Logrotate items
  create_resources('::logrotate::rule', $logrotate_rules)

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
    content => "${::fqdn}\n",
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

  #
  # Allow puppet run by CRON in testing only and with real care
  #
  if($puppet_cron and $puppet_cron_ok == 'YES, I KNOW WHAT I AM DOING, REALLY.') {
    create_resources(
      'cron',
      {'puppet-cron' => $puppet_cron},
      {
        ensure  => 'present',
        command => '/usr/bin/puppet agent -tvd --noop >> /var/log/puppet.log 2>&1 && /usr/bin/puppet agent -tvd >> /var/log/puppet.log 2>&1'
      }
    )
  }
}
