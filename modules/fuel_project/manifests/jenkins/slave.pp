# Class: fuel_project::jenkins::slave
#
# This class deploys full Jenkins slave node with all the requirements.
#
# Parameters:
#   [*docker_package*] - docker package name
#   [*ruby_version*] - ruby version to install
#   [*bind_policy*] - LDAP binding policy
#   [*bats_tests*] - install packages for bats tests
#   [*build_fuel_iso*] - install fuel iso building dependencies
#   [*build_fuel_packages*] - install packages required by fuel
#   [*build_fuel_npm_packages*] - install NPM required modules
#   [*build_fuel_plugins*] - install packages fpr fuel-plugins
#   [*check_tasks_graph*] - install tasks graph requirements
#   [*docker_config*] - create configuration file for docker
#   [*docker_config_path*] - path to docker configuration file
#   [*docker_config_user*] - user which docker will be configured for
#   [*docker_service*] - docker service name
#   [*external_host*] - host on external IP address
#   [*fuel_web_selenium*] - install packages for selenium tests
#   [*http_share_iso*] - install dependencies for sharing ISO by HTTP
#   [*install_docker*] - install docker on slave
#   [*jenkins_swarm_slave*] - enable swarm slave
#   [*known_hosts*] - known hosts to be added to known_hosts file
#   [*known_hosts_overwrite*] - erase known_hosts file before adding to it
#   [*kolla_build_tests*] - dependencies to run kolla build tests
#   [*libvirt_default_network*] - use default network for libvirt
#   [*ldap*] - use LDAP authentication
#   [*ldap_base*] - LDAP base
#   [*ldap_ignore_users*] - users ignored for LDAP checks
#   [*ldap_uri*] - LDAP URI
#   [*local_ssh_private_key*] - Jenkins SSL private key
#   [*local_ssh_public_key*] - Jenkins SSL public key
#   [*nailgun_db*] - nailgun database name
#   [*nodejs_version*] - version of 'nodejs' package
#   [*osc_apiurl*] - OSC interface URL
#   [*osc_pass_primary*] - OSC primary password
#   [*osc_pass_secondary*] - OSC secondary password
#   [*osc_url_primary*] - OSC primary URL
#   [*osc_url_secondary*] - OSC secondary URL
#   [*osc_user_primary*] - OSC primary user name
#   [*osc_user_secondary*] - OSC secondary user name
#   [*osci_centos_image_name*] - OSCI Centos image to use
#   [*osci_centos7_image_name*] - OSCI Centos7 image to use
#   [*osci_centos_job_dir*] - OSCI Centos RPMs destination directory
#   [*osci_centos_remote_dir*] - OSCI Centos remote directory name
#   [*osci_obs_jenkins_key*] - OSCI OBS Jenkins key path
#   [*osci_obs_jenkins_key_contents*] - OSCI OBS Jenkins key contents
#   [*osci_rsync_source_server*] - OSCI Rsync source server
#   [*osci_test*] - Install OSCI tests requirements
#   [*osci_trusty_image_name*] - OSCI Trusty image to use
#   [*osci_trusty_job_dir*] - OSCI Trusty Debs destination directory
#   [*osci_trusty_remote_dir*] - OSCI Trusty remote directory name
#   [*osci_ubuntu_image_name*] - OSCI Ubuntu image to use
#   [*osci_ubuntu_job_dir*] - OSCI Ubuntu Debs destination directory
#   [*osci_ubuntu_remote_dir*] - OSCI Ubuntu remote directory name
#   [*osci_vm_centos_jenkins_key*] - Centos SSH key path
#   [*osci_vm_centos_jenkins_key_contents*] - Centos SSH key contents
#   [*osci_vm_trusty_jenkins_key*] - Trusty SSH key path
#   [*osci_vm_trusty_jenkins_key_contents*] - Trusty SSH key contents
#   [*osci_vm_ubuntu_jenkins_key*] - Ubuntu SSH key path
#   [*osci_vm_ubuntu_jenkins_key_contents*] - Ubuntu SSH key contents
#   [*ostf_db*] - OSTF database name
#   [*pam_filter*] - PAM filter for LDAP
#   [*pam_password*] - PAM password type
#   [*pin_nodejs_version*] - enable or disable 'nodejs' package version pinning
#   [*run_tests*] - dependencies to run tests
#   [*seed_cleanup_dirs*] - directory locations with seeds to cleanup
#   [*simple_syntax_check*] - add syntax check tools
#   [*tls_cacertdir*] - LDAP CA certs directory
#   [*verify_fuel_astute*] - add fuel_astute verification requirements
#   [*verify_fuel_docs*] - add fuel_docs verification requirements
#   [*verify_fuel_pkgs_requirements*] - add fuel_pkgs verification requirements
#   [*verify_fuel_stats*] - add fuel_status verification requirements
#   [*verify_fuel_web*] - add fuel_web verification requirements
#   [*verify_fuel_web_npm_packages*] - add fuel_web npm packages requirements
#   [*verify_jenkins_jobs*] - add jenkins_jobs verification requirements
#   [*verify_network_checker*] - add network checker verification requirements
#   [*workspace*] - workspace directory
#   [*x11_display_num*] - X11 display number to use in tests
#
class fuel_project::jenkins::slave (
  $docker_package,
  $ruby_version,
  $bats_tests                           = false,
  $bind_policy                          = '',
  $build_fuel_iso                       = false,
  $build_fuel_npm_packages              = ['grunt-cli', 'gulp'],
  $build_fuel_packages                  = false,
  $build_fuel_plugins                   = false,
  $check_tasks_graph                    = false,
  $docker_config                        = undef,
  $docker_config_path                   = '/home/jenkins/.dockercfg',
  $docker_config_user                   = 'jenkins',
  $docker_service                       = '',
  $external_host                        = false,
  $fuel_web_selenium                    = false,
  $http_share_iso                       = false,
  $install_docker                       = false,
  $jenkins_swarm_slave                  = false,
  $known_hosts                          = {},
  $known_hosts_overwrite                = false,
  $kolla_build_tests                    = false,
  $ldap                                 = false,
  $ldap_base                            = '',
  $ldap_ignore_users                    = '',
  $ldap_uri                             = '',
  $libvirt_default_network              = false,
  $libvirt_hugepages                    = false,
  $libvirt_polkit_rules_user            = 'jenkins',
  $local_ssh_private_key                = undef,
  $local_ssh_public_key                 = undef,
  $nailgun_db                           = ['nailgun'],
  $nodejs_version                       = '0.10.25~dfsg2-2ubuntu1',
  $osc_apiurl                           = '',
  $osc_pass_primary                     = '',
  $osc_pass_secondary                   = '',
  $osc_url_primary                      = '',
  $osc_url_secondary                    = '',
  $osc_user_primary                     = '',
  $osc_user_secondary                   = '',
  $osci_centos7_image_name              = 'centos-7.qcow2',
  $osci_centos_image_name               = 'centos6.4-x86_64-gold-master.img',
  $osci_centos_job_dir                  = '/home/jenkins/vm-centos-test-rpm',
  $osci_centos_remote_dir               = 'vm-centos-test-rpm',
  $osci_obs_jenkins_key                 = '',
  $osci_obs_jenkins_key_contents        = '',
  $osci_rsync_source_server             = '',
  $osci_test                            = false,
  $osci_trusty_image_name               = 'trusty.qcow2',
  $osci_trusty_job_dir                  = '/home/jenkins/vm-trusty-test-deb',
  $osci_trusty_remote_dir               = 'vm-trusty-test-deb',
  $osci_ubuntu_image_name               = 'ubuntu-deb-test.qcow2',
  $osci_ubuntu_job_dir                  = '/home/jenkins/vm-ubuntu-test-deb',
  $osci_ubuntu_remote_dir               = 'vm-ubuntu-test-deb',
  $osci_vm_centos_jenkins_key           = '',
  $osci_vm_centos_jenkins_key_contents  = '',
  $osci_vm_trusty_jenkins_key           = '',
  $osci_vm_trusty_jenkins_key_contents  = '',
  $osci_vm_ubuntu_jenkins_key           = '',
  $osci_vm_ubuntu_jenkins_key_contents  = '',
  $ostf_db                              = ['ostf'],
  $pam_filter                           = '',
  $pam_password                         = '',
  $pin_nodejs_version                   = true,
  $run_tests                            = false,
  $seed_cleanup_dirs                    = [
    {
      'dir'     => '/var/www/fuelweb-iso', # directory to poll
      'ttl'     => 10, # time to live in days
      'pattern' => 'fuel-*', # pattern to filter files in directory
    },
    {
      'dir'     => '/srv/downloads',
      'ttl'     => 1,
      'pattern' => 'fuel-*',
    }
  ],
  $selenium_firefox_package_version     = undef,
  $simple_syntax_check                  = false,
  $tls_cacertdir                        = '',
  $verify_fuel_astute                   = false,
  $verify_fuel_docs                     = false,
  $verify_fuel_pkgs_requirements        = false,
  $verify_fuel_stats                    = false,
  $verify_fuel_web                      = false,
  $verify_fuel_web_npm_packages         = ['casperjs','grunt-cli','gulp','phantomjs'],
  $verify_jenkins_jobs                  = false,
  $verify_network_checker               = false,
  $workspace                            = '/home/jenkins/workspace',
  $x11_display_num                      = 99,
) {

  if (!defined(Class['::fuel_project::common'])) {
    class { '::fuel_project::common' :
      external_host     => $external_host,
      ldap              => $ldap,
      ldap_uri          => $ldap_uri,
      ldap_base         => $ldap_base,
      tls_cacertdir     => $tls_cacertdir,
      pam_password      => $pam_password,
      pam_filter        => $pam_filter,
      bind_policy       => $bind_policy,
      ldap_ignore_users => $ldap_ignore_users,
    }
  }

  class { 'transmission::daemon' :}

  if ($jenkins_swarm_slave == true) {
    class { '::jenkins::swarm_slave' :}
  } else {
    class { '::jenkins::slave' :}
  }


  class {'::devopslib::downloads_cleaner' :
    cleanup_dirs => $seed_cleanup_dirs,
    clean_seeds  => true,
  }

  ensure_packages([
    'git',
    'python-seed-client',
    'python-tox'
  ])

  # bats tests
  if($bats_tests) {
    ensure_packages(['bats', 'xmlstarlet'])
  }

  # bug: https://bugs.launchpad.net/fuel/+bug/1555460
  case $::osfamily {
    'Debian': {
      ensure_packages(['sqlite3', 'dutop'])
    }
    'RedHat': {
      ensure_packages(['sqlite'])
    }
    default: { }
  }

  # bug: https://bugs.launchpad.net/fuel/+bug/1497275
  case $::osfamily {
    'Debian': {
      ensure_packages(['python-yaml', 'python-git'])
    }
    'RedHat': {
      ensure_packages(['PyYAML', 'gitpython'])
    }
    default: { }
  }

  # release status reports
  if ($build_fuel_iso == true or $run_tests == true) {
    class { '::landing_page::updater' :}
  }

  # FIXME: Legacy compability LP #1418927
  cron { 'devops-env-cleanup' :
    ensure => 'absent',
  }
  file { '/usr/local/bin/devops-env-cleanup.sh' :
    ensure => 'absent',
  }
  file { '/etc/devops/local_settings.py' :
    ensure => 'absent',
  }
  file { '/etc/devops' :
    ensure  => 'absent',
    force   => true,
    require => File['/etc/devops/local_settings.py'],
  }
  package { 'python-devops' :
    ensure            => 'absent',
    uninstall_options => ['purge']
  }
  # /FIXME

  file { '/home/jenkins' :
    ensure  => 'directory',
    mode    => '0755',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }

  file { '/home/jenkins/.ssh' :
    ensure  => 'directory',
    mode    => '0700',
    owner   => 'jenkins',
    group   => 'jenkins',
    require => User['jenkins'],
  }


  if ($local_ssh_private_key) {
    file { '/home/jenkins/.ssh/id_rsa' :
      ensure  => 'present',
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $local_ssh_private_key,
      require => [
        User['jenkins'],
        File['/home/jenkins/.ssh'],
      ]
    }
  }

  if ($local_ssh_public_key) {
    file { '/home/jenkins/.ssh/id_rsa.pub' :
      ensure  => 'present',
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $local_ssh_public_key,
      require => [
        User['jenkins'],
        File['/home/jenkins/.ssh'],
      ]
    }
  }

  # 'known_hosts' manage
  if ($known_hosts) {
    create_resources('ssh::known_host', $known_hosts, {
      user      => 'jenkins',
      overwrite => $known_hosts_overwrite,
      require   => User['jenkins'],
    })
  }

  # Kolla build tests
  if ($kolla_build_tests) {
    case $::osfamily {
      'Debian': {
        $kolla_build_tests_packages = [
          'bridge-utils',
          'libxml2',
          'libxml2-dev',
          'libxslt1.1',
          'libxslt1-dev',
          'libyaml-dev',
          'lxc',
          'python-dev',
          'python-docker',
          'python-tox',
          'python-yaml',
          'sshpass',
          'vlan',
          'zlib1g-dev',
        ]
        package { 'ansible' :
          ensure => '1.9.5-1'
        }
        apt::pin { 'ansible' :
          packages => 'ansible',
          version  => '1.9.5-1',
          priority => 1000,
        }
      }
      'RedHat': {
        $kolla_build_tests_packages = [
          'python-devel',
        ]
      }
      default: { }
    }

    ensure_packages($kolla_build_tests_packages)
  }

  # Run system tests
  if ($run_tests == true) {

    if ($libvirt_default_network == false) {
      case $::osfamily {
        'Debian': {
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
        'RedHat': {
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
        default: { }
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

    $system_tests_packages_common = [
      # dependencies
      'python-psycopg2',
      'python-virtualenv',

      # diagnostic utilities
      'htop',
      'sysstat',
      'dstat',
      'tcpdump',

      # usefull utils
      'screen',

      # repo building utilities
      'reprepro',
      'createrepo',

      # monitoring
      'config-zabbix-agent-reverted-counter-item',
    ]

    ensure_packages($system_tests_packages_common)

    case $::osfamily {
      'Debian': {
        $system_tests_packages = [
          'libevent-dev',
          'libffi-dev',
          'libvirt-dev',
          'pkg-config',
          'postgresql-server-dev-all',
          'python-dev',
          'python-yaml',
          'vncviewer',
        ]
      }
      'RedHat': {
        $system_tests_packages = [
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
      }
      default: { }
    }
    ensure_packages($system_tests_packages)

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

    # Working with bridging
    # we need to load module to be sure /proc/sys/net/bridge branch will be created
    $kernel = hiera('fuel_project::common::kernel_package', '')
    if($kernel == 'linux-generic-lts-vivid') {
      $br_module = 'br_netfilter'
    }
    else {
      $br_module = 'bridge'
    }

    # ensure bridge module will be loaded on system start
    augeas { 'sysctl-net.bridge.bridge-nf-call-iptables' :
      context => '/files/etc/modules',
      changes => "clear ${br_module}",
    }

    sysctl { 'vm.swappiness' :
      value => '0',
    }
  }

  # provide env for building packages, actaully for "make sources"
  # from fuel-main and remove duplicate packages from build ISO
  if ($build_fuel_packages or $build_fuel_iso) {
    $build_fuel_packages_list_common = [
      'devscripts',
      'libparse-debcontrol-perl',
      'make',
      'mock',
      'npm',
      'pigz',
      'lzop',
      'python-setuptools',
      'python-rpm',
      'python-pbr',
      'reprepro',
      'ruby',
      'sbuild',
    ]

    # https://bugs.launchpad.net/fuel/+bug/1569341
    $nodejs_packages = [
      'nodejs',
      'nodejs-legacy',
    ]

    if ($pin_nodejs_version) {
      ensure_packages('nodejs', {
        ensure => $nodejs_version,
      })

      ensure_packages('nodejs-legacy', {
        require => Package['nodejs']
      })
    }
    else {
      ensure_packages($nodejs_packages)
    }
    # https://bugs.launchpad.net/fuel/+bug/1569341

    case $::osfamily {
      'Debian': {
        $build_fuel_packages_list = [
          'zlib1g',
          'zlib1g-dev',
        ]
      }
      'RedHat': {
        $build_fuel_packages_list = [
          'zlib',
          'zlib-devel',
        ]
      }
      default: { }
    }

    User <| title == 'jenkins' |> {
      groups  +> 'mock',
        require => [
          Package[$build_fuel_packages_list_common],
          Package[$build_fuel_packages_list],
        ]
    }
    ensure_packages($build_fuel_packages_list)

    ensure_packages($build_fuel_packages_list_common)

    if ($build_fuel_npm_packages) {
      ensure_packages($build_fuel_npm_packages, {
        provider => npm,
        require  => Package['npm'],
      })
    }
  }

  # Build ISO
  if ($build_fuel_iso == true) {
    $build_fuel_iso_packages_common = [
      'bc',
      'build-essential',
      'createrepo',
      'debmirror',
      'debootstrap',
      'dosfstools',
      'genisoimage',
      'isomd5sum',
      'kpartx',
      'lrzip',
      'python-ipaddr',
      'python-jinja2',
      'python-nose',
      'python-paramiko',
      'python-pip',
      'python-virtualenv',
      'realpath',
      'syslinux',
      'time',
      'unzip',
      'xorriso',
      'yum',
      'yum-utils',
    ]

    ensure_packages($build_fuel_iso_packages_common)

    case $::osfamily {
      'Debian': {
          # FIXME: tmp workaround regarding iso building. See #1551092 for
          # more details. To be removed after a proper fix is introduced.
          if (!defined(Package['cpio'])) {
            package { 'cpio' :
              ensure => '2.11+dfsg-1ubuntu1',
            }
          }
          create_resources('apt::pin', {
            'cpio' => {
              packages => 'cpio',
              version  => '2.11+dfsg-1ubuntu1',
              priority => 1000,
            },
          })
          # /FIXME
          $build_fuel_iso_packages = [
            'extlinux',
            'libconfig-auto-perl',
            'libmysqlclient-dev',
            'libparse-debian-packages-perl',
            'libyaml-dev',
            'python-daemon=1.5.5-1ubuntu1',
            'python-dev',
            'python-lockfile=1:0.8-2ubuntu2',
            'python-xmlbuilder',
            'python-yaml',
            'ruby-bundler',
            'ruby-builder',
            'ruby-dev',
            'rubygems-integration',
          ]
          create_resources('apt::pin', {
            'python-daemon' => {
              packages => 'python-daemon',
              version  => '1.5.5-1ubuntu1',
              priority => 1000,
            },
            'python-lockfile' => {
              packages => 'python-lockfile',
              version  => '1:0.8-2ubuntu2',
              priority => 1000,
            }
          })
      }
      'RedHat': {
        $build_fuel_iso_packages = [
          'libyaml-devel',
          'python-daemon',
          'python-devel',
          'PyYAML',
          'ruby-devel',
          'syslinux-extlinux',
        ]
      }
      default: { }
    }

    ensure_packages($build_fuel_iso_packages)

    ensure_resource('file', '/var/www', {
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    })

    ensure_resource('file', '/var/www/fwm', {
      ensure  => 'directory',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0755',
      require => [
        User['jenkins'],
        File['/var/www'],
      ],
    })

    if ($http_share_iso) {
      class { '::fuel_project::nginx' :}
      case $::osfamily {
        'Debian': {
          # jenkins should be in www-data group by default in Debian based distros
          ensure_resource('group', 'www-data', {
            ensure => 'present',
            system => true,
          })
          User <| title == 'jenkins' |> {
            groups  +> 'www-data',
          }
        }
        'RedHat': {
          # jenkins should be in nginx group by default in RHEL based distros
          ensure_resource('group', 'nginx', {
            ensure => 'present',
            system => true,
          })
          User <| title == 'jenkins' |> {
            groups  +> 'nginx',
          }
        }
        default: { }
      }

      ::nginx::resource::vhost { 'share':
        server_name => ['_'],
        autoindex   => 'on',
        www_root    => '/var/www',
      }

      ensure_resource('file', '/var/www/fuelweb-iso', {
        ensure  => 'directory',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0755',
        require => [
          User['jenkins'],
          File['/var/www'],
        ],
      })
    }

    if (!defined(Package['multistrap'])) {
      package { 'multistrap' :
        ensure => '2.1.6ubuntu3'
      }
    }
    case $::osfamily {
      'Debian': {
        apt::pin { 'multistrap' :
          packages => 'multistrap',
          version  => '2.1.6ubuntu3',
          priority => 1000,
        }
      }
      default: { }
    }

    # LP: https://bugs.launchpad.net/ubuntu/+source/libxml2/+bug/1375637
    if (!defined(Package['libxml2'])) {
      package { 'libxml2' :
        ensure => '2.9.1+dfsg1-ubuntu1',
      }
    }
    if (!defined(Package['python-libxml2'])) {
      package { 'python-libxml2' :
        ensure => '2.9.1+dfsg1-ubuntu1',
      }
    }

    case $::osfamily {
      'Debian': {
        apt::pin { 'libxml2' :
          packages => 'libxml2 python-libxml2',
          version  => '2.9.1+dfsg1-ubuntu1',
          priority => 1000,
        }
      }
      default: { }
    }
    # /LP
  }

  # FIXME: Qemu 2.4 stub to enable kvm_intel module loading {
  # Should be removed after package fix.
  if ($run_tests or $osci_test) {
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
  }

  # osci_tests - for deploying osci jenkins slaves
  if ($osci_test == true) {

    # osci needed packages
    $osci_test_packages = [
      'osc',
      'yum-utils',
    ]

    ensure_packages($osci_test_packages)

    # obs client settings
    file { 'oscrc' :
      path    => '/home/jenkins/.oscrc',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      content => template('fuel_project/jenkins/slave/oscrc.erb'),
      require => [
        Package[$osci_test_packages],
        User['jenkins'],
      ],
    }

    # osci kvm settings
    if (!defined(Class['::libvirt'])) {
      class { '::libvirt' :
        mdns_adv           => false,
        unix_sock_rw_perms => '0777',
        qemu               => true,
        defaultnetwork     => true,
      }
    }

    # osci needed directories
    file {
          [
            $osci_ubuntu_job_dir,
            $osci_centos_job_dir,
            $osci_trusty_job_dir
          ] :
      ensure  => 'directory',
      owner   => 'jenkins',
      group   => 'jenkins',
      require => User['jenkins'],
    }

    # rsync of vm images from existing rsync share
    class { 'rsync': package_ensure => 'present' }

    rsync::get { $osci_ubuntu_image_name :
      source  => "rsync://${osci_rsync_source_server}/${osci_ubuntu_remote_dir}/${osci_ubuntu_image_name}",
      path    => $osci_ubuntu_job_dir,
      timeout => 14400,
      require => [
        File[$osci_ubuntu_job_dir],
        User['jenkins'],
      ],
    }

    rsync::get { $osci_centos_image_name :
      source  => "rsync://${osci_rsync_source_server}/${osci_centos_remote_dir}/${osci_centos_image_name}",
      path    => $osci_centos_job_dir,
      timeout => 14400,
      require => [
        File[$osci_centos_job_dir],
        User['jenkins'],
      ],
    }

    rsync::get { $osci_centos7_image_name :
      source  => "rsync://${osci_rsync_source_server}/${osci_centos_remote_dir}/${osci_centos7_image_name}",
      path    => $osci_centos_job_dir,
      timeout => 14400,
      require => [
        File[$osci_centos_job_dir],
        User['jenkins'],
      ],
    }

    rsync::get { $osci_trusty_image_name :
      source  => "rsync://${osci_rsync_source_server}/${osci_trusty_remote_dir}/${osci_trusty_image_name}",
      path    => $osci_trusty_job_dir,
      timeout => 14400,
      require => [
        File[$osci_trusty_job_dir],
        User['jenkins'],
      ],
    }

    # osci needed ssh keys
    file {
        [
          $osci_obs_jenkins_key,
          $osci_vm_ubuntu_jenkins_key,
          $osci_vm_centos_jenkins_key,
          $osci_vm_trusty_jenkins_key
        ]:
      owner   => 'jenkins',
      group   => 'nogroup',
      mode    => '0600',
      content => [
        $osci_obs_jenkins_key_contents,
        $osci_vm_ubuntu_jenkins_key_contents,
        $osci_vm_centos_jenkins_key_contents,
        $osci_vm_trusty_jenkins_key_contents
      ],
      require => [
        File[
          '/home/jenkins/.ssh',
          $osci_ubuntu_job_dir,
          $osci_centos_job_dir,
          $osci_trusty_job_dir
        ],
        User['jenkins'],
      ],
    }
  }

  # *** Custom tests ***

  # anonymous statistics tests
  if ($verify_fuel_stats) {
    class { '::fuel_stats::tests' : }
  }

  # Web tests by verify-fuel-web, stackforge-verify-fuel-web, verify-fuel-ostf
  if ($verify_fuel_web) {
    $verify_fuel_web_packages_common = [
      'inkscape',
      'nodejs-legacy',
      'npm',
      'python-cloud-sptheme',
      'python-sphinx',
      'python-tox',
      'python-virtualenv',
      'rst2pdf',
    ]

    ensure_packages($verify_fuel_web_packages_common)

    case $::osfamily {
      'Debian': {
        $verify_fuel_web_packages = [
          'libxslt1-dev',
          'postgresql-server-dev-all',
          'python-all-dev',
          'python2.6',
          'python2.6-dev',
          'python3-dev',
        ]
      }
      'RedHat': {
        $verify_fuel_web_packages = [
          'libxslt-devel',
          'postgresql-devel',
          'python-devel',
          'python26',
          'python26-devel',
          'python34-devel',
        ]
      }
      default: { }
    }
    ensure_packages($verify_fuel_web_packages)

    if ($verify_fuel_web_npm_packages) {
      ensure_packages($verify_fuel_web_npm_packages, {
        provider => npm,
        require  => Package['npm'],
      })
    }

    if ($fuel_web_selenium) {
      $selenium_packages_common = [
        'chromium-browser',
        'chromium-chromedriver',
        'imagemagick',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-cyrillic',
        'xfonts-scalable',
      ]

      if ($selenium_firefox_package_version) {
        package { 'firefox' :
          ensure => $selenium_firefox_package_version,
        }
        create_resources('apt::pin', {
          'firefox' => {
            packages => 'firefox',
            version  => $selenium_firefox_package_version,
            priority => 1000,
          },
        })
      }
      else {
        package { 'firefox' :
          ensure => 'latest',
        }
      }

      ensure_packages($selenium_packages_common)

      case $::osfamily {
        'Debian': {
            $selenium_packages = [
              'x11-apps',
            ]
        }
        'RedHat': {
          $selenium_packages = [
            'xorg-x11-apps',
          ]
        }
        default: { }
      }
      ensure_packages($selenium_packages)

      class { 'display' :
        display => $x11_display_num,
        width   => 1366,
        height  => 768,
      }
    }

    if (!defined(Class['postgresql::server'])) {
      class { 'postgresql::server' : }
    }

    postgresql::server::db { $nailgun_db:
      user     => 'nailgun',
      password => 'nailgun',
    }
    postgresql::server::db { $ostf_db:
      user     => 'ostf',
      password => 'ostf',
    }

    postgresql::server::pg_hba_rule { 'Allow local TCP connections with authentication under postgres user' :
      description => 'Allow local TCP connections with authentication under postgres user',
      type        => 'host',
      database    => 'all',
      user        => 'postgres',
      address     => '127.0.0.1/32',
      auth_method => 'md5',
    }

    postgresql::server::pg_hba_rule { 'Allow local connections with authentication under postgres user' :
      description => 'Allow local connections with authentication under postgres user',
      type        => 'local',
      database    => 'all',
      user        => 'postgres',
      auth_method => 'md5',
    }

    file { '/var/log/nailgun' :
      ensure  => directory,
      owner   => 'jenkins',
      require => User['jenkins'],
    }
  }

  # For the below roles we need to have rvm base class
  if ($verify_fuel_astute or $simple_syntax_check or $build_fuel_plugins) {
    class { 'rvm' : }
    rvm::system_user { 'jenkins': }
    rvm_system_ruby { "ruby-${ruby_version}" :
      ensure      => 'present',
      default_use => true,
      require     => Class['rvm'],
    }
  }


  # Astute tests require only rvm package
  if ($verify_fuel_astute) {
    rvm_gem { 'bundler' :
      ensure       => 'present',
      ruby_version => "ruby-${ruby_version}",
      require      => Rvm_system_ruby["ruby-${ruby_version}"],
    }
    # FIXME: remove this hack, create package raemon?
    $raemon_file = '/tmp/raemon-0.3.0.gem'
    file { $raemon_file :
      source => 'puppet:///modules/fuel_project/gems/raemon-0.3.0.gem',
    }
    rvm_gem { 'raemon' :
      ensure       => 'present',
      ruby_version => "ruby-${ruby_version}",
      source       => $raemon_file,
      require      => [ Rvm_system_ruby["ruby-${ruby_version}"], File[$raemon_file] ],
    }
  }

  if ($verify_network_checker) {
    $verify_network_checker_packages_common = [
      'python-tox',
      'python-virtualenv',

    ]
    ensure_packages($verify_network_checker_packages_common)
    case $::osfamily {
      'Debian': {
        $verify_network_checker_packages = [
          'libpcap-dev',
          'python-all-dev',
          'python2.6',
          'python2.6-dev',
          'python3-dev',
        ]
      }
      'RedHat': {
        $verify_network_checker_packages = [
          'libpcap-devel',
          'python-devel',
          'python26',
          'python26-devel',
          'python3-devel',
        ]
      }
      default: { }
    }
    ensure_packages($verify_network_checker_packages)
  }

  # Simple syntax check by:
  # - verify-fuel-devops
  # - fuellib_review_syntax_check (puppet tests)
  if ($simple_syntax_check) {
    $syntax_check_packages_common = [
      'puppet-lint',
      'python-flake8',
      'python-tox',
    ]

    ensure_packages($syntax_check_packages_common)

    case $::osfamily {
      'Debian': {
        $syntax_check_packages = [
          'libxslt1-dev',
        ]
      }
      'RedHat': {
        $syntax_check_packages = [
          'libxslt-devel',
        ]
      }
      default: { }
    }
    ensure_packages($syntax_check_packages)

    rvm_gem { 'puppet-lint' :
      ensure       => 'installed',
      ruby_version => "ruby-${ruby_version}",
      require      => Rvm_system_ruby["ruby-${ruby_version}"],
    }
  }

  # Check tasks graph
  if ($check_tasks_graph){
    $tasks_graph_check_packages = [
      'python-pytest',
      'python-jsonschema',
      'python-networkx',
    ]

    ensure_packages($tasks_graph_check_packages)
  }

  # Verify Fuel docs
  if ($verify_fuel_docs) {
    $verify_fuel_docs_packages_common =  [
      'inkscape',
      'make',
      'plantuml',
      'python-cloud-sptheme',
      'python-sphinx',
      'python-sphinxcontrib.plantuml',
      'rst2pdf',
      'texlive-font-utils', # provides epstopdf binary
    ]

    ensure_packages($verify_fuel_docs_packages_common)

    case $::osfamily {
      'Debian': {
        $verify_fuel_docs_packages = [
          'libjpeg-dev',
        ]
      }
      'RedHat': {
        $verify_fuel_docs_packages = [
          'libjpeg-turbo-devel',
        ]
      }
      default: { }
    }
    ensure_packages($verify_fuel_docs_packages)
  }

  # Verify Jenkins jobs
  if ($verify_jenkins_jobs) {
    $verify_jenkins_jobs_packages = [
      'python-tox',
      'shellcheck',
    ]

    ensure_packages($verify_jenkins_jobs_packages)
  }

  # Verify and Build fuel-plugins project
  if ($build_fuel_plugins) {
    $build_fuel_plugins_packages_common = [
      'rpm',
      'createrepo',
      'dpkg-dev',
      'make',
      'gcc',
      'python-tox',
      'python-virtualenv',
    ]

    ensure_packages($build_fuel_plugins_packages_common)

    case $::osfamily {
      'Debian': {
        $build_fuel_plugins_packages = [
          'libyaml-dev',
          'python-dev',
          'python2.6',
          'python2.6-dev',
          'ruby-dev',
        ]
      }
      'RedHat': {
        $build_fuel_plugins_packages = [
          'libyaml-devel',
          'python-devel',
          'python26',
          'python26-devel',
          'ruby-devel',
        ]
      }
      default: { }
    }
    ensure_packages($build_fuel_plugins_packages)

    # we also need fpm gem
    rvm_gem { 'fpm' :
      ensure       => 'present',
      ruby_version => "ruby-${ruby_version}",
      require      => [
        Rvm_system_ruby["ruby-${ruby_version}"],
        Package['make'],
      ],
    }
  }

  # verify requirements-{deb|rpm}.txt files from fuel-main project
  # test-requirements-{deb|rpm} jobs on fuel-ci
  if ($verify_fuel_pkgs_requirements==true){
    $verify_fuel_requirements_packages = [
      'devscripts',
      'yum-utils',
    ]

    ensure_packages($verify_fuel_requirements_packages)
  }

  if ($install_docker or $build_fuel_iso or $build_fuel_packages) {
    if (!$docker_package) {
      fail('You must define docker package explicitly')
    }

    if (!defined(Package[$docker_package])) {
      package { $docker_package :
        ensure  => 'present',
        require => Package['lxc-docker'],
      }
    }

    #actually docker have api, and in some cases it will not be automatically started and enabled
    if ($docker_service and (!defined(Service[$docker_service]))) {
      service { $docker_service :
        ensure    => 'running',
        enable    => true,
        hasstatus => true,
        require   => [
          Package[$docker_package],
          Group['docker'],
        ],
      }
    }

    # create configuration file for docker
    if ($docker_config) {
      file { $docker_config_path:
        ensure  => 'present',
        owner   => $docker_config_user,
        group   => $docker_config_user,
        mode    => '0400',
        content => $docker_config,
        require => User['jenkins'],
      }
    }

    package { 'lxc-docker' :
      ensure => 'absent',
    }

    group { 'docker' :
      ensure  => 'present',
      require => Package[$docker_package],
    }

    User <| title == 'jenkins' |> {
      groups  +> 'docker',
      require => Group['docker'],
    }

    if ($external_host) {
      firewall { '010 accept all to docker0 interface':
        proto   => 'all',
        iniface => 'docker0',
        action  => 'accept',
        require => Package[$docker_package],
      }
    }
  }
}
