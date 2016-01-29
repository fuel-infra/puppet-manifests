# Class: obs_server::nginx
#
# This class deploys Nginx part of OBS.
#
# Parameters:
#   [*access_log_file*] - access log file path
#   [*error_log_file*] - error log file path
#   [*ssl_key_file*] - SSL key file path
#   [*ssl_cert_file*] - SSL certificate file path
#   [*ssl_key_file_contents*] - SSL key file contents
#   [*ssl_cert_file_contents*] - SSL certificate file contents
#
class obs_server::nginx (
  $access_log_file = '/srv/www/obs/api/log/nginx-obs-api-access.log',
  $error_log_file = '/srv/www/obs/api/log/nginx-obs-api-error.log',
  $ssl_key_file = '/srv/obs/certs/server.key',
  $ssl_cert_file = '/srv/obs/certs/server.crt',
  $ssl_key_file_contents = '',
  $ssl_cert_file_contents = '',
) inherits obs_server::folders {

package { 'nginx':
  ensure => installed,
}

package { 'rubygem-passenger-nginx':
  ensure  => installed,
}

##### folders and files #######

file { [ '/etc/nginx/conf.d','/etc/nginx/vhosts.d',]:
  ensure  => 'directory',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  require => Package['nginx'],
}

file { 'nginx_obs-server_config':
  ensure  => present,
  path    => '/etc/nginx/vhosts.d/obs-server.conf',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  force   => true,
  require => File['/etc/nginx/vhosts.d'],
  notify  => Service ['nginx'],
  content => template('obs_server/nginx_obs-server.conf.erb'),
}

file { 'nginx_internal_redirect.include':
  ensure  => present,
  path    => '/etc/nginx/vhosts.d/internal_redirect.include',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  force   => true,
  require => File['/etc/nginx/vhosts.d'],
  notify  => Service ['nginx'],
  content => template('obs_server/nginx_internal_redirect.include.erb'),
}

file { $ssl_key_file:
  owner   => 'root',
  group   => 'root',
  mode    => '0400',
  content => $ssl_key_file_contents,
  require => File ['/srv/obs/certs'],
}

file { $ssl_cert_file:
  owner   => 'root',
  group   => 'root',
  mode    => '0400',
  content => $ssl_cert_file_contents,
  require => File[$ssl_key_file],
  notify  => Service['nginx'],
}

service { 'nginx':
  ensure  => 'running',
  enable  => true,
  require => File['/srv/www/obs/api/log'],
}

}
