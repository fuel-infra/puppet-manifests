# Class: fuel_project::jenkins::slave
#
class fuel_project::jenkins::slave (
  $external_host         = false,
  $build_fuel_iso        = false,
  $run_tests             = false,
  $simple_syntax_check   = false,
  $verify_fuel_web       = false,
  $verify_fuel_astute    = false,
  $verify_fuel_docs      = false,
  $ldap                  = false,
  $fuelweb_iso           = false,
  $ldap_uri              = '',
  $ldap_base             = '',
  $tls_cacertdir         = '',
  $pam_password          = '',
  $pam_filter            = '',
  $sudoers_base          = '',
  $bind_policy           = '',
  $ldap_ignore_users     = '',
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
  include venv
  include system_tests
  include transmission_daemon

  if $external_host == true {
    class { '::jenkins::slave' :}

    ssh::known_host { 'review.openstack.org-known-hosts' :
      host    => 'review.openstack.org',
      port    => 29418,
      user    => 'jenkins',
      require => Class['::jenkins::slave'],
    }
  } else {
    class { '::jenkins::swarm_slave' :}
  }

  # Run system tests
  if ($run_tests == true) {
    class { '::libvirt' :
      listen_tls         => false,
      listen_tcp         => true,
      auth_tcp           => 'none',
      mdns_adv           => false,
      unix_sock_group    => 'libvirtd',
      unix_sock_rw_perms => '0777',
      python             => true,
      qemu               => true,
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

    if ! defined(Package['qemu-kvm']) {
      package { 'qemu-kvm' :
        ensure => installed
      }
    }
  }

  # Buiid ISO
  if ($build_fuel_iso == true) {
    class { '::build_fuel_iso' :
      external_host => $external_host,
    }
  }

  # *** Custom tests ***

  # Web tests by verify-fuel-web, stackforge-verify-fuel-web
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

    if (!defined(Class['postgresql::server'])) {
      class { 'postgresql::server' : }
    }

    postgresql::server::db { 'nailgun':
      user     => 'nailgun',
      password => 'nailgun',
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
    ]

    ensure_packages($verify_fuel_docs_packages)
  }

  if ($fuelweb_iso) {
    class { '::nginx::share' :
      fuelweb_iso_create => true,
    }
  }
}
