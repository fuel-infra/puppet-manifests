# Class: gerrit::hideci
#
# This class installs hideci package and creates configuration file for it.
#
# Parameters:
#   [*ci_regex*] - CI name regex used
#     Example: '/^(openstack-ci-.*|mos-infra-ci|ci-build-.*$/'
#
class gerrit::hideci (
  $ci_regex = '//',
) {

  package { 'hideci':
    ensure  => present,
  }

  # Hideci sets these permissions in 'init'; don't fight them.
  # Template uses:
  # - $ciRegex
  file { '/etc/hideci.js/config.js':
    ensure  => present,
    content => template('gerrit/config.js.erb'),
    require => Package['hideci'],
  }

  file { '/var/lib/gerrit/review_site/static/config.js' :
    ensure  => link,
    target  => '/etc/hideci.js/config.js',
    require => [
      File['/etc/hideci.js/config.js'],
      Package['hideci'],
    ],
  }


}
