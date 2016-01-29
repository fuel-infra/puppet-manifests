# Class: obs_server::mysql
#
# This class deploys MySQL database for OBS.
#
# Parameters:
#   [*db_name*] - database name
#   [*db_user*] - database user
#   [*db_password*] - database password
#
class obs_server::mysql (
  $db_name = 'obs',
  $db_user = 'obs',
  $db_password = 'obs',
){

require mysql::server::account_security

  class { 'mysql::server':
  }

############ creation of user and database #######################

mysql::db { $db_name:
  user     => $db_user,
  password => $db_password,
  host     => 'localhost',
  grant    => ['CREATE','DROP','INSERT','UPDATE','SELECT','INDEX','DELETE'],
  notify   => Exec['create_obs_db'],
}

############ implementation of database and user ######################

file { 'obs_db_config':
  ensure  => present,
  path    => '/srv/www/obs/api/config/database.yml',
  owner   => 'root',
  group   => 'www',
  mode    => '0644',
  force   => true,
  replace => true,
  require => Package['obs-api'],
  content => template('obs_server/database.yml.erb'),
}

exec { 'create_obs_db':
  onlyif  => "/usr/bin/mysqlshow -u${db_user} -p${db_password} ${db_name}",
  command => '/usr/bin/rake RAILS_ENV=production -f /srv/www/obs/api/Rakefile db:create',
  require => File['obs_db_config'],
}

exec { 'install_obs_db':
  unless  => "/usr/bin/mysqlshow -u${db_user} -p${db_password} ${db_name} users",
  command => '/usr/bin/rake RAILS_ENV=production -f /srv/www/obs/api/Rakefile db:setup',
  require => Exec['create_obs_db'],
}

}
