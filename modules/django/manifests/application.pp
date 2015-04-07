# Define: django::application
#
define django::application (
  $admins          = hiera_array("django::application::${title}::admins", []),
  $apps            = hiera_array("django::application::${title}::apps", []),
  $config          = hiera("django::application::${title}::config", "/etc/${title}/settings.py"),
  $config_mode     = hiera("django::application::${title}::config_mode", '0400'),
  $config_template = hiera("django::application::${title}::config_template", 'django/settings.py.erb'),
  $database_engine = hiera("django::application::${title}::database_engine", undef),
  $database_host   = hiera("django::application::${title}::database_host", undef),
  $database_name   = hiera("django::application::${title}::database_name", undef),
  $database_socket = hiera("django::application::${title}::database_socket", undef),
  $database_user   = hiera("django::application::${title}::database_user", undef),
  $debug           = hiera("django::application::${title}::debug", false),
  $group           = hiera("django::application::${title}::group", 'nogroup'),
  $packages        = hiera_array("django::application::${title}::packages", []),
  $template_debug  = hiera("django::application::${title}::template_debug", false),
  $user            = hiera("django::application::${title}::user", 'nobody'),
  $uwsgi           = hiera("django::application::${title}::uwsgi", true),
  $uwsgi_chdir     = hiera("django::application::${title}::uwsgi_chdir", undef),
  $uwsgi_module    = hiera("django::application::${title}::uwsgi_module", undef),
  $uwsgi_socket    = hiera("django::application::${title}::uwsgi_socket", '127.0.0.1:12345'),
) {
  if ($packages == [] or $packages == '') {
    fatal('$packages could not be empty')
  }

  ensure_packages($packages)

  group { $group :
    ensure => 'present',
    system => true,
  }

  user { $user :
    ensure     => 'present',
    home       => "/var/lib/${user}",
    managehome => true,
    shell      => '/usr/sbin/nologin',
    system     => true,
  }

  file { $config :
    ensure  => 'present',
    mode    => $config_mode,
    owner   => $user,
    group   => $group,
    content => template($config_template),
    require => Package[$packages],
  }

  if ($uwsgi and $uwsgi_chdir and $uwsgi_module and $uwsgi_socket) {
    ::uwsgi::application { $title :
      plugins => 'python',
      uid     => $user,
      gid     => $group,
      socket  => $uwsgi_socket,
      chdir   => $uwsgi_chdir,
      module  => $uwsgi_module,
      require => [
        Package[$packages],
        User[$user],
      ],
    }
  }
}
