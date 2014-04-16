class pxetool {
  include nginx

  include pxetool::params

  $packages = $pxetool::params::packages

  package { $packages :
    ensure => latest,
  }
}
