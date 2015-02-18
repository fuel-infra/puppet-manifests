# Class: fuel_project::jenkins::slave
#
class fuel_project::jenkins::slave (
  $external_host           = false,
  $build_fuel_iso          = false,
  $run_tests               = false,
  $simple_syntax_check     = false,
  $verify_fuel_web         = false,
  $verify_fuel_astute      = false,
  $verify_fuel_docs        = false,
  $fuel_web_selenium       = false,
  $build_fuel_plugins      = false,
  $install_docker          = false,
  $verify_fuel_stats       = false,
  $ldap                    = false,
  $fuelweb_iso             = false,
  $check_tasks_graph       = false,
  $ldap_uri                = '',
  $ldap_base               = '',
  $nailgun_db              = ['nailgun'],
  $ostf_db                 = ['ostf'],
  $tls_cacertdir           = '',
  $pam_password            = '',
  $pam_filter              = '',
  $sudoers_base            = '',
  $bind_policy             = '',
  $ldap_ignore_users       = '',
  $seed_cleanup_dirs       = [
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
  $jenkins_swarm_slave     = false,
  $docker_package          = '',
  $sudo_commands           = ['/sbin/ebtables'],
  $workspace               = '/home/jenkins/workspace',
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

    ssh::known_host { 'review.openstack.org-known-hosts' :
      host    => 'review.openstack.org',
      port    => 29418,
      user    => 'jenkins',
      require => Class['::jenkins::slave'],
    }
  }

  ensure_packages(['git', 'python-seed-cleaner', 'python-seed-client'])

  file { '/usr/local/bin/seed-downloads-cleanup.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('fuel_project/common/seed-downloads-cleanup.sh.erb'),
    require => Package['python-seed-cleaner'],
  }

  cron { 'seed-downloads-cleanup' :
    command => '/usr/local/bin/seed-downloads-cleanup.sh 2>&1 | logger -t seed-downloads-cleanup',
    user    => root,
    hour    => '*/4',
    minute  => 0,
    require => File['/usr/local/bin/seed-downloads-cleanup.sh'],
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
      'python-seed-cleaner',
      'python-seed-client',
      'pkg-config',
      'libffi-dev',
      'libvirt-dev',
      'postgresql-server-dev-all',
      'mock',

      # diagnostic utilities
      'htop',
      'sysstat',
      'dstat',
      'vncviewer',
      'tcpdump',

      # usefull utils
      'screen',
      'mc',
    ]

    ensure_packages($system_tests_packages)

    file { $workspace :
      ensure  => 'directory',
      user    => 'jenkins',
      require => User['jenkins'],
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

  # Build ISO
  if ($build_fuel_iso == true) {
    $build_fuel_iso_packages = [
      'bc',
      'build-essential',
      'createrepo',
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
      'nodejs',
      'nodejs-legacy',
      'npm',
      'python-daemon',
      'python-ipaddr',
      'python-jinja2',
      'python-nose',
      'python-paramiko',
      'python-pbr',
      'python-pip',
      'python-setuptools',
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
      require => [ User['jenkins'],  File['/var/www'] ],
    })

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

    exec { 'install-grunt-cli' :
      command   => '/usr/bin/npm install -g grunt-cli',
      logoutput => on_failure,
    }

    file { 'jenkins-sudo-for-build_iso' :
      path    => '/etc/sudoers.d/build_fuel_iso',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('fuel_project/jenkins/slave/build_iso.sudoers.d.erb')
    }

    Package[$build_fuel_iso_packages]->
      Exec['install-grunt-cli']
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

    ensure_packages($verify_fuel_web_packages)

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
    exec { 'install_global_npm' :
      command => '/usr/bin/npm -g install grunt-cli casperjs phantomjs',
      require => Package['npm'],
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

  if ($fuelweb_iso) {
    class { '::nginx' :}
    nginx::resource::vhost { 'share':
      server_name => ['_'],
      autoindex   => 'on',
      www_root    => '/var/www',
    }

    ensure_resource('file', '/var/www/fuelweb-iso', {
      ensure  => 'directory',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0755',
      require => [ User['jenkins'],  File['/var/www'] ],
    })
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
    package { 'fpm' :
      ensure   => 'present',
      provider => 'gem',
      require  => Package['make'],
    }
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

}
