# Class: hideci
#
class hideci (
  $ciRegex = '//',
) {
  package { 'hideci':
    ensure  => present,
    require => [
      File['/etc/hideci.js'],
    ],
  }

  # Hideci sets these permissions in 'init'; don't fight them.
  # Template uses:
  # - $ciRegex
  file { '/etc/hideci.js':
    ensure  => link,
    target  => '/var/lib/gerrit/review_site/etc/config.js',
    content => template('hideci/hideci.js.erb'),
    replace => true,
  }
}
