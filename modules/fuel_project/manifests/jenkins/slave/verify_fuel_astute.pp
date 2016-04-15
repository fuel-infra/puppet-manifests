# Class: fuel_project::jenkins::slave::verify_fuel_astute
#
# Class sets up verify_fuel_astute role
#
class fuel_project::jenkins::slave::verify_fuel_astute {
  include ::rvm
  $raemon_file = '/tmp/raemon-0.3.0.gem'
  $ruby_version = '2.1.5'

  file { $raemon_file :
    source => 'puppet:///modules/fuel_project/gems/raemon-0.3.0.gem',
  }
  include ::rvm
  ensure_resource('rvm_system_ruby', "ruby-${ruby_version}", {
    ensure      => 'present',
    default_use => true,
    require     => Class['rvm'],
  })
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
