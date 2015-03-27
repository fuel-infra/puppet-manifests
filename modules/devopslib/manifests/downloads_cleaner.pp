# Class: devopslib::downloads_cleaner

#
class devopslib::downloads_cleaner (
  $cleanup_dirs = undef,
  $clean_seeds = false,
){
  if (! $cleanup_dirs) {
    fail('You must define cleanup_dirs explicitly')
  }

  if ($clean_seeds) {
    ensure_packages(['python-seed-cleaner'])
  }

  file { '/usr/local/bin/seed-downloads-cleanup.sh' :
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('devopslib/seed-downloads-cleanup.sh.erb'),
  }

  cron { 'seed-downloads-cleanup' :
    command => '/usr/local/bin/seed-downloads-cleanup.sh 2>&1 | logger -t seed-downloads-cleanup',
    user    => root,
    hour    => '*/4',
    minute  => 0,
    require => File['/usr/local/bin/seed-downloads-cleanup.sh'],
  }

}