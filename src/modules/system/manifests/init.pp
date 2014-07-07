class system {
  include system::rootmail

  $packages = $system::params::packages

  Realize Package[$packages]
}
