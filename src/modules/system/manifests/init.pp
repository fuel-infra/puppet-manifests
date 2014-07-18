class system {
  include system::rootmail
  include system::tools
  include virtual::packages
  include virtual::users

  $packages = $system::params::packages

  realize Package[$packages]
  realize User['root']
}
