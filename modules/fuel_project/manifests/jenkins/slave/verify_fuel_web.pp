# Class: fuel_project::jenkins::slave::verify_fuel_web
#
# Class sets up verify_fuel_web role
#
class fuel_project::jenkins::slave::verify_fuel_web (
  $selenium = false,
) {
  $packages = [
    'inkscape',
    'npm',
    'python-cloud-sptheme',
    'python-sphinx',
    'python-tox',
    'python-virtualenv',
    'rst2pdf',
  ]

  case $::osfamily {
    'Debian': {
      $debian_packages = [
        'libxslt1-dev',
        'postgresql-server-dev-all',
        'python-all-dev',
        'python2.6',
        'python2.6-dev',
        'python3-dev',
      ]

      case $::lsbdistcodename {
        'trusty': {
          $distro_packages = [
            'nodejs=0.10.25~dfsg2-2ubuntu1',
            'nodejs-legacy=0.10.25~dfsg2-2ubuntu1',
          ]
          create_resources('apt::pin', {
            'nodejs' => {
              packages => 'nodejs',
              version  => '0.10.25~dfsg2-2ubuntu1',
              priority => 1000,
            },
            'nodejs-legacy' => {
              packages => 'nodejs-legacy',
              version  => '0.10.25~dfsg2-2ubuntu1',
              priority => 1000,
            },
          })
        }
        'xenial': {
          $distro_packages = []
        }
        default: {
          $distro_packages = []
        }
      }

      $additional_packages = concat($debian_packages, $distro_packages)
    }
    'RedHat': {
      $additional_packages = [
        'libxslt-devel',
        'postgresql-devel',
        'python-devel',
        'python26',
        'python26-devel',
        'python34-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }
  ensure_packages(concat($packages, $additional_packages))

  case $::lsbdistcodename {
    'xenial': {
      $npm_packages = [
        'casperjs',
        'gulp',
        'phantomjs-prebuilt',
      ]
    }
    'trusty': {
      $npm_packages = [
        'casperjs',
        'grunt-cli',
        'gulp',
        'phantomjs',
      ]
    }
    default: {
      $npm_packages = []
    }
  }

  if ($npm_packages) {
    ensure_packages($npm_packages, {
      provider => npm,
      require  => Package['npm'],
    })
  }

  if ($selenium) {
    $selenium_packages_common = [
      'chromium-browser',
      'chromium-chromedriver',
      'firefox',
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

  $nailgun_db = [
    'nailgun',
    'nailgun0',
    'nailgun1',
    'nailgun2',
    'nailgun3',
    'nailgun4',
    'nailgun5',
    'nailgun6',
    'nailgun7',
  ]

  $ostf_db = ['ostf']

  postgresql::server::db { $nailgun_db :
    user     => 'nailgun',
    password => 'nailgun',
  }

  postgresql::server::db { $ostf_db :
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
