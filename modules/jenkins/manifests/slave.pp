# Class: jenkins::slave
#
# This class deploys Jenkins slave package and keys.
#
# Parameters:
#   [*java_package*] - Java package name
#
class jenkins::slave (
  $java_package = $::jenkins::params::slave_java_package,
) inherits ::jenkins::params {
  ensure_packages([$java_package])

  if (!defined(User['jenkins'])) {
    user { 'jenkins' :
      ensure     => 'present',
      name       => 'jenkins',
      shell      => '/bin/bash',
      home       => '/home/jenkins',
      managehome => true,
      system     => true,
      comment    => 'Jenkins',
    }
  }
}
