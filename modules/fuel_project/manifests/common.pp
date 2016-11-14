# Class: fuel_project::common
#
# This class deploys basic requirements for fuel_project classes.
#
# Parameters:
#   [*bind_policy*] - LDAP binding policy
#   [*external_host*] - host deployed on external IP address
#   [*filebeat*] - boolean to choose if the Filebeat log shipper should be installed
#   [*hugepages*] - boolean/string/integer, value for kernel hugepages parameter
#   [*hugepagesz*] - string/integer, value for kernel hugepagesz parameter
#   [*kernel_package*] - kernel package to install
#   [*ldap*] - use LDAP authentication
#   [*ldap_base*] - LDAP base
#   [*ldap_ignore_users*] - users ignored for LDAP checks
#   [*ldap_uri*] - LDAP URI
#   [*network_detection*] - autodetect network settings using DNS query
#   [*pam_filter*] - PAM filter for LDAP
#   [*pam_password*] - PAM password type
#   [*puppet_cron*] - run Puppet agent by cron
#   [*puppet_cron_ok*] - "YES, I KNOW WHAT I AM DOING, REALLY" - to confirm
#   [*root_password_hash*] - root password
#   [*root_shell*] - shell for root user
#   [*ruby_version*] - Ruby version to be installed
#   [*ssh_keys_group*] - SSH key group to apply
#   [*tls_cacertdir*] - LDAP CA certs directory
#
# Hiera parameters:
#   [*known_hosts*] - hash, variables which are passed to ssh::known_host via
#                     create_resources to manage known_hosts file
#     Example:
#      fuel_project::common::known_hosts:
#        'user':
#          home: '/some/special/directory'
#          overwrite: false
#          hosts:
#           'www.example.com':
#             port: 2233
#             home: '/even/more/special/directory'
#           'www.google.com':
#             port: 22
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
#   [*tune2fs*] - Hash, options to pass to tune2fs class
#     $tune2fs = {
#       '/dev/vda1' => {
#         'action' => 'reserved_percentage',
#         'value'  => '0.5',
#     }
#
class fuel_project::common (
  $bind_policy        = '',
  $external_host      = false,
  $filebeat           = false,
  $hugepages          = false,
  $hugepagesz         = undef,
  $kernel_package     = undef,
  $known_hosts        = {},
  $ldap               = false,
  $ldap_base          = '',
  $ldap_ignore_users  = '',
  $ldap_uri           = '',
  $network_detection  = false,
  $pam_filter         = '',
  $pam_password       = '',
  $puppet_cron        = {},
  $puppet_cron_ok     = '',
  $root_password_hash = 'r00tme',
  $root_shell         = '/bin/bash',
  $ruby_version       = undef,
  $ssh_keys_group     = '',
  $tls_cacertdir      = '',
  $tune2fs            = {},
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

  # setup static network configuration if requested
  if($network_detection and $autonetwork_interface) {
    file { '/etc/network/interfaces' :
      ensure  => 'present',
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => template('fuel_project/common/interfaces.erb'),
    }
  }

  class { '::atop' :}
  if($filebeat) {
    class { '::log_storage::filebeat' :}
  }
  class { '::ntp' :}
  class { '::puppet::agent' :}
  class { '::ssh::authorized_keys' :}

  # if ssh_keys_group is provided - apply SSH keys group
  if($ssh_keys_group) {
    $keys = hiera_hash("common::infra::${ssh_keys_group}::ssh_keys", {})
    create_resources(ssh_authorized_key,
      $keys, {
        ensure => present,
        user => 'root'
      }
    )
  }

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
  ], { ensure  => latest })

  # 'known_hosts' manage
  if ($known_hosts) {
    create_resources('ssh::known_host', $known_hosts)
  }

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
      include ::apt
      Apt::Source <| |> -> Package <| |>
    }
    'RedHat': {
      include ::yum
      include ::yum::repos
      $yum_repos_gpgkey = hiera_hash('yum::gpgkey', {})
      create_resources('::yum::gpgkey', $yum_repos_gpgkey)
      $yum_versionlock = hiera_hash('yum::versionlock', {})
      create_resources('::yum::versionlock', $yum_versionlock)
      Yum::Gpgkey <| |> -> Package <| tag !='yum-plugin' |>
      Yumrepo <| |> -> Package <| |>
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

  # hugepages support (PDPE1GB flag is required)
  if ($hugepages) {
    # prepare mount point
    file { 'hugepages':
      ensure => 'directory',
      path   => '/hugepages',
    }
    mount { '/hugepages':
      ensure  => 'mounted',
      atboot  => true,
      device  => 'hugetlbfs',
      fstype  => 'hugetlbfs',
      options => 'mode=1777',
      require => File['hugepages'],
    }
    # prepare kernel options
    kernel_parameter { 'hugepagesz':
      ensure => present,
      value  => $hugepagesz,
    }
    kernel_parameter { 'hugepages':
      ensure  => present,
      value   => $hugepages,
      require => Kernel_parameter['hugepagesz'],
    }
  }

  class { '::tune2fs' :
    tune2fs => $tune2fs,
  }

  # install Ruby globally
  include ::rvm
  ensure_resource('rvm_system_ruby', "ruby-${ruby_version}", {
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
  })

}
