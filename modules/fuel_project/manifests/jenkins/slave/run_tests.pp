# Class: fuel_project::jenkins::slave::run_tests
#
# Class sets up run_tests role.
#
# Parameters:
#   [*ksm*] - enable KSM on server on Ubuntu harware host
#
class fuel_project::jenkins::slave::run_tests (
  $ksm = false,
) {
  include ::landing_page::updater

  $packages = [
    'config-zabbix-agent-reverted-counter-item',
    'createrepo',
    'dstat',
    'htop',
    'python-psycopg2',
    'python-virtualenv',
    'reprepro',
    'sysstat',
    'tcpdump',
  ]

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'libevent-dev',
        'libffi-dev',
        'libldap2-dev',
        'libsasl2-dev',
        'libvirt-dev',
        'pkg-config',
        'postgresql-server-dev-all',
        'python-dev',
        'vncviewer',
      ]

      case $::lsbdistcodename {
        'xenial': {
          class { '::libvirt' :
            listen_tls         => false,
            listen_tcp         => true,
            auth_tcp           => 'none',
            mdns_adv           => false,
            unix_sock_group    => 'libvirtd',
            unix_sock_rw_perms => '0777',
            python             => true,
            qemu               => true,
            tcp_port           => 16509,
            deb_default        => {
              'libvirtd_opts' => '-l',
            },
          }
        }
        default: {
          class { '::libvirt' :
            listen_tls         => false,
            listen_tcp         => true,
            auth_tcp           => 'none',
            mdns_adv           => false,
            unix_sock_group    => 'libvirtd',
            unix_sock_rw_perms => '0777',
            python             => true,
            qemu               => true,
            tcp_port           => 16509,
            deb_default        => {
              'libvirtd_opts' => '-d -l',
            },
          }
        }
      }
    }
    'RedHat': {
      $additional_packages = [
        'libevent-devel',
        'libffi-devel',
        'libvirt-devel',
        'openssl-devel',
        'pkgconfig',
        'postgresql-devel',
        'python-devel',
        'PyYAML',
        'gtk-vnc2',
      ]

      class { '::libvirt' :
        listen_tls         => false,
        listen_tcp         => true,
        auth_tcp           => 'none',
        mdns_adv           => false,
        unix_sock_group    => 'libvirt',
        unix_sock_rw_perms => '0777',
        python             => true,
        qemu               => true,
        tcp_port           => 16509,
        sysconfig          => {
          'LIBVIRTD_ARGS' => '--listen',
        }
      }
    }
    default: {
      $additional_packages = []
    }
  }

  ensure_packages(concat($packages, $additional_packages))

  if($::virtual == 'physical') {
    if($::processor0 =~ /^Intel/) {
      file { '/etc/modprobe.d/qemu-system-x86.conf' :
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options kvm_intel nested=1'
      }
      # load kvm_intel module only if Intel cpu found.
      exec { '/sbin/modprobe kvm_intel' :
        user      => 'root',
        logoutput => 'on_failure',
        require   => File['/etc/modprobe.d/qemu-system-x86.conf'],
      }
    } else {
      warning("qemu-kvm modules was not loaded because processor vendor is not Intel. Don't what to load :(")
    }
  }

  libvirt_pool { 'default' :
    ensure    => 'present',
    type      => 'dir',
    autostart => true,
    target    => '/var/lib/libvirt/images',
    require   => Class['libvirt'],
  }

  # Add a jenkins user to the kvm group
  User <| title == 'jenkins' |> {
    groups  +> 'kvm',
    require => [
      Package['libvirt'],
    ],
  }

  # python-devops installation
  if (!defined(Class['::postgresql::server'])) {
    class { '::postgresql::server' : }
  }

  ::postgresql::server::db { 'devops' :
    user     => 'devops',
    password => 'devops',
  }

  ::postgresql::server::db { 'fuel_devops' :
    user     => 'fuel_devops',
    password => 'fuel_devops',
  }
  # /python-devops installation

  $workspace = '/home/jenkins/workspace'
  file { $workspace :
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  ensure_resource('file', "${workspace}/iso", {
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => [
      User['jenkins'],
      File[$workspace],
    ],
  })

  # Kernel same-page merging (KSM)
  # https://review.fuel-infra.org/27136 - KSM init.d package
  if ($ksm) {
    ensure_packages('ksm')
  }

  # Working with bridging
  # we need to load module to be sure /proc/sys/net/bridge branch will be created
  $kernel = hiera('fuel_project::common::kernel_package', '')
  if($kernel == 'linux-generic-lts-vivid') {
    $br_module = 'br_netfilter'
  } else {
    $br_module = 'bridge'
  }

  # ensure bridge module will be loaded on system start
  augeas { 'sysctl-net.bridge.bridge-nf-call-iptables' :
    context => '/files/etc/modules',
    changes => "clear ${br_module}",
  }

  exec { "/sbin/modprobe ${br_module}" :
    logoutput => 'on_failure',
    require   => Augeas['sysctl-net.bridge.bridge-nf-call-iptables'],
  }

  Exec["/sbin/modprobe ${br_module}"] -> Sysctl <| |>

  sysctl { 'vm.swappiness' :
    value => '0',
  }
}
