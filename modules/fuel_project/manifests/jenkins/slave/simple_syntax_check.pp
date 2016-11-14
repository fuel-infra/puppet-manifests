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

  # install additional Ruby dependencies
  include ::rvm
  $ruby_version = hiera('fuel_project::common::ruby_version')
  ensure_resource('rvm::system_user', 'jenkins', {})
  rvm_gem { 'puppet-lint' :
    ensure       => 'installed',
    ruby_version => "ruby-${ruby_version}",
    require      => Rvm_system_ruby["ruby-${ruby_version}"],
  }
}
