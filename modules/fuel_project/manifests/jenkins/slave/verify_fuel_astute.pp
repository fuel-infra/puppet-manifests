# Class: fuel_project::jenkins::slave::verify_fuel_astute
#
# Class sets up verify_fuel_astute role
#
class fuel_project::jenkins::slave::verify_fuel_astute {

  # install additional Ruby dependencies
  include ::rvm
  $ruby_version = hiera('fuel_project::common::ruby_version')
  $raemon_file = '/tmp/raemon-0.3.0.gem'

  file { $raemon_file :
    source => 'puppet:///modules/fuel_project/gems/raemon-0.3.0.gem',
  }

  ensure_resource('rvm::system_user', 'jenkins', {})
  rvm_gem { 'bundler' :
    ensure       => 'present',
    ruby_version => "ruby-${ruby_version}",
    require      => Rvm_system_ruby["ruby-${ruby_version}"],
  }
  rvm_gem { 'raemon' :
    ensure       => 'present',
    ruby_version => "ruby-${ruby_version}",
    source       => $raemon_file,
    require      => [
      Rvm_system_ruby["ruby-${ruby_version}"],
      File[$raemon_file] ],
  }
}
