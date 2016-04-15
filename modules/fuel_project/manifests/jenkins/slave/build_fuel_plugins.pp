# Class: fuel_project::jenkins::slave::build_fuel_plugins
#
# Class sets up build_fuel_plugins role
#
class fuel_project::jenkins::slave::build_fuel_plugins {
  include ::rvm

  $packages = [
    'cmake',
    'createrepo',
    'dpkg-dev',
    'liblua5.1',
    'lua-cjson',
    'lua-unit',
    'lua5.1',
    'make',
    'gcc',
    'python-tox',
    'python-virtualenv',
    'rpm',
  ]
  $ruby_version = '2.1.5'

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

  ensure_resource('rvm_system_ruby', "ruby-${ruby_version}", {
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
  })

  rvm_gem { 'fpm' :
    ensure       => 'present',
    ruby_version => "ruby-${ruby_version}",
    require      => [
      Rvm_system_ruby["ruby-${ruby_version}"],
      Package['make'],
    ],
  }
}
