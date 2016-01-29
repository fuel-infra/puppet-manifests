# Class: obs_server::folders
#
# The folders and permissions which are required
# but not exist after package installation
#
class obs_server::folders{

file { [ '/srv/obs/','/srv/obs/certs',]:
  ensure  => 'directory',
  owner   => 'root',
  group   => 'root',
  mode    => '0700',
  require => Package['obs-api'],
}

file { '/srv/www/obs/api/log':
  ensure  => 'directory',
  owner   => 'wwwrun',
  group   => 'www',
  force   => true,
  recurse => true,
  require => Package['obs-api'],
}

file { '/srv/www/obs/api/tmp':
  ensure  => 'directory',
  owner   => 'wwwrun',
  group   => 'www',
  recurse => true,
  require => File['/srv/www/obs/api/log'],
}

file { '/srv/obs/repos':
  ensure  => 'directory',
  owner   => 'wwwrun',
  group   => 'www',
  recurse => true,
}

file {'/srv/www/obs/api/log/backend_access.log':
  ensure  => 'present',
  owner   => 'wwwrun',
  group   => 'www',
  require => File['/srv/www/obs/api/log'],
}

}
