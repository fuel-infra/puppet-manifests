class system {
  include system::rootmail
  include virtual::packages

  $packages = $system::params::packages

  realize Package[$packages]
}
