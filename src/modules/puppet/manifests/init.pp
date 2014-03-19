class puppet {
  include puppet::params

  $packages = $puppet::params::packages

  package { $packages :
    ensure => latest,
  }
}
