# Class: fuel_project::jenkins::slave::simple_syntax_check
#
# Class sets up simple_syntax_check role
#
class fuel_project::jenkins::slave::simple_syntax_check {
  $packages = [
    'puppet-lint',
    'python-flake8',
    'python-tox',
  ]
  $ruby_version = '2.1.5'

  case $::osfamily {
    'Debian': {
      $additional_packages = [
        'libxslt1-dev',
      ]
    }
    'RedHat': {
      $additional_packages = [
        'libxslt-devel',
      ]
    }
    default: {
      $additional_packages = []
    }
  }
  ensure_packages(concat($packages, $additional_packages))

  include ::rvm
  ensure_resource('rvm::system_user', 'jenkins')
  ensure_resource('rvm_system_ruby', "ruby-${ruby_version}", {
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
  })

  rvm_gem { 'puppet-lint' :
    ensure       => 'installed',
    ruby_version => "ruby-${ruby_version}",
    require      => Rvm_system_ruby["ruby-${ruby_version}"],
  }
}
