# Class: puppet::auth
#
# This class is about to configure native puppet ACLs from
#   /etc/puppet/auth.conf
#
# Parameters:
#  [*acl*] - dict, configuration to use
#    dict in the following form:
#      $acl = {
#        '/' => {                   # path
#           method => 'find,save',  # methods to allow
#           allow  => '*',          # hosts to allow
#           auth   => 'any',        # auth flag
#        }
#      }
#    Allowed options:
#      [environment envlist]
#      [method methodlist]
#      [auth[enthicated] {yes|no|on|off|any}]
#      allow [host|backreference|*|regex]
#      deny [host|backreference|*|regex]
#      allow_ip [ip|cidr|ip_wildcard|*]
#      deny_ip [ip|cidr|ip_wildcard|*]
#  [*purge_defaults*] - boolean, if we should cleanup default ACLs
#
class puppet::auth (
  $acl = {},
  $purge_defaults = false,
) {
  file { '/etc/puppet/auth.conf' :
    ensure  => 'present',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0400',
    content => template('puppet/auth.conf.erb'),
  }
}
