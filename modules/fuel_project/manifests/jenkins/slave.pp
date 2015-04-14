# Class: fuel_project::jenkins::slave
#
class fuel_project::jenkins::slave (
  $docker_package,
  $external_host                        = false,
  $build_fuel_iso                       = false,
  $build_fuel_plugins                   = false,
  $build_fuel_packages                  = false,
  $run_tests                            = false,
  $simple_syntax_check                  = false,
  $verify_fuel_web                      = false,
  $verify_fuel_astute                   = false,
  $verify_fuel_docs                     = false,
  $fuel_web_selenium                    = false,
  $install_docker                       = false,
  $verify_fuel_stats                    = false,
  $verify_fuel_pkgs_requirements        = false,
  $ldap                                 = false,
  $http_share_iso                       = false,
  $check_tasks_graph                    = false,
  $osci_test                            = false,
  $osci_rsync_source_server             = '',
  $osci_ubuntu_image_name               = 'ubuntu-deb-test.qcow2',
  $osci_centos_image_name               = 'centos6.4-x86_64-gold-master.img',
  $osci_trusty_image_name               = 'trusty.qcow2',
  $osci_ubuntu_job_dir                  = '/home/jenkins/vm-ubuntu-test-deb',
  $osci_centos_job_dir                  = '/home/jenkins/vm-centos-test-rpm',
  $osci_trusty_job_dir                  = '/home/jenkins/vm-trusty-test-deb',
  $osci_ubuntu_remote_dir               = 'vm-ubuntu-test-deb',
  $osci_centos_remote_dir               = 'vm-centos-test-rpm',
  $osci_trusty_remote_dir               = 'vm-trusty-test-deb',
  $osci_obs_jenkins_key                 = '',
  $osci_obs_jenkins_key_contents        = '',
  $osci_vm_ubuntu_jenkins_key           = '',
  $osci_vm_ubuntu_jenkins_key_contents  = '',
  $osci_vm_centos_jenkins_key           = '',
  $osci_vm_centos_jenkins_key_contents  = '',
  $osci_vm_trusty_jenkins_key           = '',
  $osci_vm_trusty_jenkins_key_contents  = '',
  $osci_dhcp_start                      = '',
  $osci_dhcp_end                        = '',
  $osci_ip_address                      = '',
  $osci_ip_netmask                      = '',
  $osci_libvirt_dev                     = '',
  $osc_apiurl                           = '',
  $osc_url_primary                      = '',
  $osc_user_primary                     = '',
  $osc_pass_primary                     = '',
  $osc_url_secondary                    = '',
  $osc_user_secondary                   = '',
  $osc_pass_secondary                   = '',
  $obs_known_hosts                      = 'osci-obs.vm.mirantis.net',
  $ldap_uri                             = '',
  $ldap_base                            = '',
  $nailgun_db                           = ['nailgun'],
  $ostf_db                              = ['ostf'],
  $tls_cacertdir                        = '',
  $pam_password                         = '',
  $pam_filter                           = '',
  $sudoers_base                         = '',
  $bind_policy                          = '',
  $ldap_ignore_users                    = '',
  $ldap_sudo_group                      = undef,
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
  $jenkins_swarm_slave                  = false,
  $docker_service                       = '',
  $sudo_commands                        = ['/sbin/ebtables'],
  $workspace                            = '/home/jenkins/workspace',
  $gerrit_host                          =  'review.openstack.org',
  $gerrit_port                          = 29418,
  $overwrite_known_hosts                = true,
  $local_ssh_private_key                = undef,
  $local_ssh_public_key                 = undef,
) {
  class { '::fuel_project::common' :
    external_host     => $external_host,
    ldap              => $ldap,
    ldap_uri          => $ldap_uri,
    ldap_base         => $ldap_base,
    tls_cacertdir     => $tls_cacertdir,
    pam_password      => $pam_password,
    pam_filter        => $pam_filter,
    sudoers_base      => $sudoers_base,
    bind_policy       => $bind_policy,
    ldap_ignore_users => $ldap_ignore_users,
  }

  class { 'transmission::daemon' :}

  if $jenkins_swarm_slave == true {
    class { '::jenkins::swarm_slave' :}
  } else {
    class { '::jenkins::slave' :}

    ssh::known_host { 'slave-known-hosts' :
      host      => $gerrit_host,
      port      => $gerrit_port,
      user      => 'jenkins',
      overwrite => $overwrite_known_hosts,
      require   => Class['::jenkins::slave'],
    }
  }

  class {'::devopslib::downloads_cleaner' :
    cleanup_dirs => $seed_cleanup_dirs,
    clean_seeds  => true,
  }

  ensure_packages(['git', 'python-seed-client'])

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

  # Run system tests
  if ($run_tests == true) {
    class { '::libvirt' :
      listen_tls         => false,
      listen_tcp         => true,
      auth_tcp           => 'none',
      listen_addr        => '127.0.0.1',
      mdns_adv           => false,
      unix_sock_group    => 'libvirtd',
      unix_sock_rw_perms => '0777',
      python             => true,
      qemu               => true,
      tcp_port           => 16509,
      deb_default        => {
        'libvirtd_opts' => '-d -l',
      }
    }

    libvirt_pool { 'default' :
      ensure    => 'present',
      type      => 'dir',
      autostart => true,
      target    => '/var/lib/libvirt/images',
      require   => Class['libvirt'],
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

    $system_tests_packages = [
      # dependencies
      'libevent-dev',
      'libffi-dev',
      'libvirt-dev',
      'python-dev',
      'python-psycopg2',
      'python-virtualenv',
      'python-yaml',
      'pkg-config',
      'postgresql-server-dev-all',

      # diagnostic utilities
      'htop',
      'sysstat',
      'dstat',
      'vncviewer',
      'tcpdump',

      # usefull utils
      'screen',

      # repo building utilities
      'reprepro',
      'createrepo',
    ]

    ensure_packages($system_tests_packages)

    file { $workspace :
      ensure  => 'directory',
      owner   => 'jenkins',
      group   => 'jenkins',
      require => User['jenkins'],
    }

    augeas { 'sysctl-net.bridge.bridge-nf-call-iptables' :
      context => '/files/etc/modules',
      changes => 'clear bridge',
    }

    file { '/etc/sudoers.d/systest' :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template('fuel_project/jenkins/slave/system_tests.sudoers.d.erb'),
    }

    sysctl { 'net.bridge.bridge-nf-call-iptables' :
      value   => '0',
      require => Package[$system_tests_packages],
    }
  }

  # provide env for building packages, actaully for "make sources"
  # from fuel-main and remove duplicate packages from build ISO
  if ($build_fuel_packages or $build_fuel_iso) {
    $build_fuel_packages_list = [
      'make',
      'nodejs',
      'nodejs-legacy',
      'npm',
      'python-setuptools',
      'python-pbr',
      'ruby',
    ]

    $build_fuel_npm_packages = [
      'grunt-cli',
      'gulp',
    ]

    ensure_packages($build_fuel_packages_list)

    ensure_packages($build_fuel_npm_packages, {
      provider => npm,
      require  => Package['npm'],
    })
  }

  # Build ISO
  if ($build_fuel_iso == true) {
    $build_fuel_iso_packages = [
      'bc',
      'build-essential',
      'createrepo',
      'debmirror',
      'debootstrap',
      'extlinux',
      'genisoimage',
      'isomd5sum',
      'kpartx',
      'libconfig-auto-perl',
      'libmysqlclient-dev',
      'libparse-debian-packages-perl',
      'libyaml-dev',
      'lrzip',
      'python-daemon',
      'python-ipaddr',
      'python-jinja2',
      'python-nose',
      'python-paramiko',
      'python-pip',
      'python-xmlbuilder',
      'python-yaml',
      'realpath',
      'ruby-bundler',
      'ruby-builder',
      'ruby-dev',
      'rubygems-integration',
      'syslinux',
      'unzip',
      'yum',
      'yum-utils',
    ]

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
    apt::pin { 'multistrap' :
      packages => 'multistrap',
      version  => '2.1.6ubuntu3',
      priority => 1000,
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
    apt::pin { 'libxml2' :
      packages => 'libxml2 python-libxml2',
      version  => '2.9.1+dfsg1-ubuntu1',
      priority => 1000,
    }
    # /LP

    file { 'jenkins-sudo-for-build_iso' :
      path    => '/etc/sudoers.d/build_fuel_iso',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('fuel_project/jenkins/slave/build_iso.sudoers.d.erb')
    }

  }

  # osci_tests - for deploying osci jenkins slaves
  if ($osci_test == true) {

    # osci needed packages
    $osci_test_packages = [
      'osc',
    ]

    ensure_packages($osci_test_packages)

    # sudo for user 'jenkins'
    file { 'jenkins-sudo-for-osci-vm' :
      path    => '/etc/sudoers.d/jenkins_sudo',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('fuel_project/jenkins/slave/build_iso.sudoers.d.erb'),
      require => User['jenkins'],
    }

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

    $dhcp = {
      'start' => $osci_dhcp_start,
      'end'   => $osci_dhcp_end,
    }

    $ip = {
      'address' => $osci_ip_address,
      'netmask' => $osci_ip_netmask,
      'dhcp'    => $dhcp,
    }

    libvirt::network { 'osci_testjob_network' :
      forward_dev => $osci_libvirt_dev,
      ip          => [ $ip ],
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

    # obs host key
    ssh::known_host { 'obs-known-hosts' :
      host      => $obs_known_hosts,
      user      => 'jenkins',
      overwrite => $overwrite_known_hosts,
      require   => Class['::jenkins::slave'],
    }
  }

  # *** Custom tests ***

  # anonymous statistics tests
  if $verify_fuel_stats {
    class { '::fuel_stats::tests' : }
  }

  # Web tests by verify-fuel-web, stackforge-verify-fuel-web, verify-fuel-ostf
  if $verify_fuel_web {
    $verify_fuel_web_packages = [
      'inkscape',
      'libxslt1-dev',
      'nodejs-legacy',
      'npm',
      'python-all-dev',
      'python-cloud-sptheme',
      'python-sphinx',
      'python-tox',
      'python-virtualenv',
      'python2.6',
      'python2.6-dev',
      'rst2pdf',
    ]

    $verify_fuel_web_npm_packages = [
      'casperjs',
      'grunt-cli',
      'gulp',
      'phantomjs',
    ]

    ensure_packages($verify_fuel_web_packages)

    ensure_packages($verify_fuel_web_npm_packages, {
      provider => npm,
      require  => Package['npm'],
    })

    if ($fuel_web_selenium) {
      $selenium_packages = [
        'chromium-browser',
        'chromium-chromedriver',
        'xvfb',
      ]
      ensure_packages($selenium_packages)
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
    file { '/var/log/nailgun' :
      ensure  => directory,
      owner   => 'jenkins',
      require => User['jenkins'],
    }
  }

  # Astute tests require only rvm package
  if $verify_fuel_astute {
    class { 'rvm' : }
    rvm::system_user { 'jenkins': }
    rvm_system_ruby { 'ruby-2.1.2' :
      ensure      => 'present',
      default_use => true,
      require     => Class['rvm'],
    }
    rvm_gem { 'bundler' :
      ensure       => 'present',
      ruby_version => 'ruby-2.1.2',
      require      => Rvm_system_ruby['ruby-2.1.2'],
    }
    # FIXME: remove this hack, create package raemon?
    $raemon_file = '/tmp/raemon-0.3.0.gem'
    file { $raemon_file :
      source => 'puppet:///modules/fuel_project/gems/raemon-0.3.0.gem',
    }
    rvm_gem { 'raemon' :
      ensure       => 'present',
      ruby_version => 'ruby-2.1.2',
      source       => $raemon_file,
      require      => [ Rvm_system_ruby['ruby-2.1.2'], File[$raemon_file] ],
    }

    if ($simple_syntax_check) {
      rvm_gem { 'puppet-lint' :
        ensure       => 'installed',
        ruby_version => 'ruby-2.1.2',
        require      => Rvm_system_ruby['ruby-2.1.2'],
      }
    }
  }

  # Simple syntax check by:
  # - verify-fuel-devops
  # - fuellib_review_syntax_check (puppet tests)
  if ($simple_syntax_check) {
    $syntax_check_packages = [
      'libxslt1-dev',
      'puppet-lint',
      'python-flake8',
      'python-tox',
    ]

    ensure_packages($syntax_check_packages)
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
    $verify_fuel_docs_packages =  [
      'inkscape',
      'make',
      'plantuml',
      'python-cloud-sptheme',
      'python-sphinx',
      'python-sphinxcontrib.plantuml',
      'rst2pdf',
      'texlive-font-utils', # provides epstopdf binary
    ]

    ensure_packages($verify_fuel_docs_packages)
  }

  # Verify and Build fuel-plugins project
  if ($build_fuel_plugins) {
    $build_fuel_plugins_packages = [
      'rpm',
      'createrepo',
      'dpkg-dev',
      'libyaml-dev',
      'make',
      'python-dev',
      'ruby-dev',
      'gcc',
      'python2.6',
      'python2.6-dev',
      'python-tox',
      'python-virtualenv',
    ]

    ensure_packages($build_fuel_plugins_packages)

    # we also need fpm gem
    if (!defined(Class['::rvm'])) {
      rvm::system_user { 'jenkins': }
      rvm_system_ruby { 'ruby-2.1.2' :
        ensure      => 'present',
        default_use => true,
        require     => Class['rvm'],
      }
    }
    rvm_gem { 'fpm' :
      ensure       => 'present',
      ruby_version => 'ruby-2.1.2',
      require      => [ Rvm_system_ruby['ruby-2.1.2'],
                      Package['make'] ],
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

  if $install_docker or $build_fuel_iso {
    if !$docker_package {
      fail('You must define docker package explicitly')
    }

    if (!defined(Package[$docker_package])) {
      package { $docker_package :
        ensure  => 'present',
        require => Package['lxc-docker'],
      }
    }

    #actually docker have api, and in some cases it will not be automatically started and enabled
    if $docker_service and (!defined(Service[$docker_service])) {
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

    package { 'lxc-docker' :
      ensure => 'absent',
    }

    group { 'docker' :
      ensure  => 'present',
      require => Package[$docker_package],
    }

    User <| title == 'jenkins' |> {
      groups  => ['www-data', 'docker'],
      require => Group['docker'],
    }

    if $external_host {
      firewall { '010 accept all to docker0 interface':
        proto   => 'all',
        iniface => 'docker0',
        action  => 'accept',
        require => Package[$docker_package],
      }
    }
  }

  if($ldap_sudo_group) {
    file { '/etc/sudoers.d/sandbox':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template('fuel_project/jenkins/slave/sandbox.sudoers.d.erb'),
    }
  }
}
