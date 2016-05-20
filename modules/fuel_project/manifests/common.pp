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
#   [*logstash_forwarder*] - enable logstash forwarder
#   [*pam_filter*] - PAM filter for LDAP
#   [*pam_password*] - PAM password type
#   [*puppet_cron*] - run Puppet agent by cron
#   [*puppet_cron_ok*] - "YES, I KNOW WHAT I AM DOING, REALLY" - to confirm
#   [*root_password_hash*] - root password
#   [*root_shell*] - shell for root user
#   [*tls_cacertdir*] - LDAP CA certs directory
#
# Additional parameters:
#
#   [*apparmor*] = Hash, sets up custom apparmor rules.
#     Example:
#       $apparmor => {
#         '/usr/sbin/libvirtd' => {
#           ensure => 'disabled'
#         },
#       }
#
#     Default: {}
#
#   [*facts*] - Hash, sets up custom facts through hiera. Example:
#     $facts = {
#       location => 'location_name',
#       blah     => 'blah value',
#     }
#
#   [*files*] - Hash, file create options. Example:
#     $files = {
#       '/hugepages' => {
#         'ensure'  => 'directory',
#       }
#     }
#
#     Default:
#       $mounts = {}
#
#   [*hosts*] - Hash, sets up custom /etc/hosts content through hiera. Default:
#     $hosts = {
#       "${::fqdn} ${::hostname}"              => '127.0.1.1',
#       'localhost'                            => '127.0.0.1',
#       'localhost ip6-localhost ip6-loopback' => '::1',
#       'ip6-allnodes'                         => 'ff02::1',
#       'ip6-allrouters'                       => 'ff02::2',
#     }
#
#   [*kernel_parameters*] - Hash, paramters to be updated in GRUB for kernel.
#     Example:
#       $kernel_parameters = {
#         'transparent_hugepage' => {
#           ensure => 'present',
#           value  => 'never',
#         },
#         'hugepagesz' => {
#           ensure => 'present',
#           value  => '1G',
#         },
#         'hugepages' => {
#           ensure => 'present',
#           value  => '256',
#         },
#         'default_hugepagesz' => {
#           ensure => 'present',
#           value  => '1G',
#         },
#       }
#     Default: {}
#
#   [*logrotate_rules*] - Hash, log rotate rules. Example:
#     $logrotate_rules = {
#       'upstart' => {
#         'path'          => '/var/log/upstart/*.log',
#         'rotate_every'  => 'day',
#         'rotate'        => 7,
#         'missingok'     => true,
#         'compress'      => true,
#         'ifempty'       => false,
#         'create'        => false,
#         'delaycompress' => true,
#       }
#     }
#
#     Default:
#       $logrotate_rules = {}
#
#   [*mounts*] - Hash, /etc/fstab custom options. Example:
#     $mounts = {
#       '/' => {
#         'ensure'  => 'present',
#         'options' => 'defaults,errors=remount-ro,noatime,nodiratime,barrier=0',
#       }
#     }
#
#     Default:
#       $mounts = {}
#
class fuel_project::common (
  $bind_policy        = '',
  $external_host      = false,
  $kernel_package     = undef,
  $ldap               = false,
  $ldap_base          = '',
  $ldap_ignore_users  = '',
  $ldap_uri           = '',
  $logstash_forwarder = false,
  $pam_filter         = '',
  $pam_password       = '',
  $puppet_cron        = {},
  $puppet_cron_ok     = '',
  $root_password_hash = 'r00tme',
  $root_shell         = '/bin/bash',
  $tls_cacertdir      = '',
) {
  $apparmor = hiera_hash('fuel_project::common::apparmor', {})

  $facts = hiera_hash('fuel_project::common::facts', {
    'location' => $::location,
    'role'     => $::role,
  })

  $hosts = hiera_hash('fuel_project::common::hosts', {
    "${::fqdn} ${::hostname}"              => '127.0.1.1',
    'localhost'                            => '127.0.0.1',
    'localhost ip6-localhost ip6-loopback' => '::1',
    'ip6-allnodes'                         => 'ff02::1',
    'ip6-allrouters'                       => 'ff02::2',
  })


  $files = hiera_hash('fuel_project::common::files', {})
  $kernel_parameters = hiera_hash('fuel_project::common::kernel_parameters', {})
  $logrotate_rules = hiera_hash('logrotate::rules', {})
  $mounts = hiera_hash('fuel_project::common::mounts', {})

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

  # install apparmor if Debian family
  if ($apparmor and $::osfamily == 'Debian') {
    include ::apparmor

    create_resources('apparmor::profile', $apparmor, {})
  }

  create_resources('kernel_parameter', $kernel_parameters, {
    ensure => 'present'})

  ensure_packages([
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
      class { '::yum::repos' :}
      $yum_repos_gpgkey = hiera_hash('yum::gpgkey', {})
      create_resources('::yum::gpgkey', $yum_repos_gpgkey)
      $yum_versionlock = hiera_hash('yum::versionlock', {})
      create_resources('::yum::versionlock', $yum_versionlock)
      Yum::Gpgkey <| |> -> Package <| tag !='yum-plugin' |>
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

  create_resources(file, $files)
  create_resources(mount, $mounts)

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
