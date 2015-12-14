# Class: firewall_defaults::post
#
# Simple class which is run after all the other firewall roles to not allow any
# more connections (except already declarated).
#
class firewall_defaults::post {
  firewall { '9999 drop all':
    proto  => 'all',
    action => 'drop',
    before => undef,
  }
}
