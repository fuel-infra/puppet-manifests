# Class: gerrit::hideci
#
class gerrit::hideci (
  $ciRegex = '//',
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
