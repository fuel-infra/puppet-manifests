# Define: uwsgi::application
#
# This definition sets up uwsgi application entry.
#
# Parameters:
#   [*buffer_size*] - application buffer size
#   [*callable*] - entry point into the application
#   [*chdir*] - application working directory
#   [*chmod*] - socket privileges
#   [*enable_threads*] - enable threads support
#   [*env*] - set environment value
#   [*gid*] - group to run application in
#   [*home*] - Python home directory
#   [*listen*] - socket listen queue size
#   [*master*] - enable master process
#   [*module*] - load a WSGI module
#   [*plugins*] - load uWSGI plugins
#   [*rack*] - load a rack app
#   [*socket*] - bind to the specified UNIX/TCP socket using default protocol
#   [*subscribe*] - Resource or array of resources to notify Service['uwsgi'] on
#   [*uid*] - user to run application as
#   [*vacuum*] - try to remove all of the generated file/sockets
#   [*workers*] - spawn the specified number of workers/processes
#
define uwsgi::application (
  $buffer_size    = 65535,
  $callable       = undef,
  $chdir          = '/',
  $chmod          = 644,
  $enable_threads = true,
  $env            = undef,
  $gid            = 'www-data',
  $home           = undef,
  $lazy_apps      = undef,
  $listen         = 1000,
  $master         = true,
  $module         = undef,
  $plugins        = undef,
  $rack           = undef,
  $socket         = undef,
  $subscribe      = undef,
  $uid            = 'www-data',
  $vacuum         = true,
  $workers        = $::processorcount,
) {
  include ::uwsgi::params

  if (!defined(Class['::uwsgi'])) {
    class { '::uwsgi' :}
  }

  validate_string($plugins)

  ensure_packages($::uwsgi::params::plugins_packages[$plugins])

  file { "/etc/uwsgi/apps-available/${title}.yaml" :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('uwsgi/application.yaml.erb'),
    require => [
      Package[$::uwsgi::params::package],
      Package[$::uwsgi::params::plugins_packages[$plugins]],
    ],
    notify  => Service[$::uwsgi::params::service],
  }

  file { "/etc/uwsgi/apps-enabled/${title}.yaml" :
    ensure  => 'link',
    target  => "/etc/uwsgi/apps-available/${title}.yaml",
    notify  => Service[$::uwsgi::params::service],
    require => File["/etc/uwsgi/apps-available/${title}.yaml"],
  }

  if($subscribe) {
    $subscribe ~> Service[$::uwsgi::params::service]
  }
}
