# Class: fuel_project::robots
#
# This class configures a robots.txt file for a web-server.
#
class fuel_project::robots {

  $rules = hiera_hash('fuel_project::robots::rules', {})

  create_resources(file, $rules, {
    ensure  => 'present',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
  })
}
