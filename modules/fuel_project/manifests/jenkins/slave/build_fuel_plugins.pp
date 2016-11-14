# Class: fuel_project::jenkins::slave::build_fuel_plugins
#
# Class sets up build_fuel_plugins role
#
class fuel_project::jenkins::slave::build_fuel_plugins {

  $packages = [
    'cmake',
    'createrepo',
    'dpkg-dev',
    'gcc',
    'libldap2-dev',
    'liblua5.1',
    'libsasl2-dev',
    'lua-cjson',
    'lua-unit',
    'lua5.1',
    'make',
    'python-tox',
    'python-virtualenv',
    'rpm',
  ]

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'libyaml-dev',
        'python-dev',
        'python2.6',
        'python2.6-dev',
        'ruby-dev',
      ]
    }
    'RedHat': {
      $additional_packages = [
        'libyaml-devel',
        'python-devel',
        'python26',
        'python26-devel',
        'ruby-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }

  ensure_packages(concat($packages, $additional_packages))

  # install additional Ruby dependencies
  include ::rvm
  $ruby_version = hiera('fuel_project::common::ruby_version')
  rvm_gem { 'fpm' :
    ensure       => 'present',
    ruby_version => "ruby-${ruby_version}",
    require      => [
      Rvm_system_ruby["ruby-${ruby_version}"],
      Package['make'],
    ],
  }
}
