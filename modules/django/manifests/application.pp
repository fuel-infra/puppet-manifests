# Define: django::application
#
# This class deploys django database config file and uwsgi daemon setup.
# It does not cover Nginx configuration - only uwsgi daemon will listen.
#
# Parameters:
#  [*additional_parameters*] - additional parameters in django settings file
#  [*admins*] - username, e-mail pairs of admin users
#  [*apps*] - apps included in django settings file
#  [*config*] - django configuration files location
#  [*config_mode*] - django configuration files mode
#  [*config_template*] - django settings file template
#  [*database*] - django database settings file entries
#  [*debug*] - enable debug mode
#  [*group*] - django installation working group
#  [*imports*] - imports used in django app
#  [*logging*] - django logging settings file entries
#  [*packages*] - system packages required by application
#  [*secret_key*] - django application secret key
#  [*template_debug*] - enable template debug mode
#  [*user*] - django installation working user
#  [*uwsgi*] - install uwsgi interface
#  [*uwsgi_chdir*] - uwsgi chdir setting
#  [*uwsgi_module*] - uwsgi module setting
#  [*uwsgi_socket*] - uwsgi listening socket
#  [*uwsgi_vacuum*] - uwsgi vacuum setting
#  [*uwsgi_workers*] - uwsgi workers amount
#
define django::application (
  $additional_parameters = hiera_hash("django::application::${title}::additional_parameters", {}),
  $admins                = hiera_array("django::application::${title}::admins", []),
  $apps                  = hiera_array("django::application::${title}::apps", []),
  $config                = hiera("django::application::${title}::config", "/etc/${title}/settings.py"),
  $config_mode           = hiera("django::application::${title}::config_mode", '0400'),
  $config_template       = hiera("django::application::${title}::config_template", 'django/settings.py.erb'),
  $database              = hiera_hash("django::application::${title}::database", undef),
  $debug                 = hiera("django::application::${title}::debug", false),
  $group                 = hiera("django::application::${title}::group", 'nogroup'),
  $imports               = hiera_array("django::application::${title}::imports"),
  $logging               = hiera_hash("django::application::${title}::logging"),
  $packages              = hiera_array("django::application::${title}::packages", []),
  $secret_key            = hiera("django::application::${title}::secret_key", ''),
  $template_debug        = hiera("django::application::${title}::template_debug", false),
  $user                  = hiera("django::application::${title}::user", 'nobody'),
  $uwsgi                 = hiera("django::application::${title}::uwsgi", true),
  $uwsgi_chdir           = hiera("django::application::${title}::uwsgi_chdir", undef),
  $uwsgi_master          = hiera("django::application::${title}::uwsgi_master", undef),
  $uwsgi_module          = hiera("django::application::${title}::uwsgi_module", undef),
  $uwsgi_socket          = hiera("django::application::${title}::uwsgi_socket", '127.0.0.1:12345'),
  $uwsgi_vacuum          = hiera("django::application::${title}::uwsgi_vacuum", undef),
  $uwsgi_workers         = hiera("django::application::${title}::uwsgi_workers", undef),
) {
  if ($packages == [] or $packages == '') {
    fatal('$packages could not be empty')
  }

  if ($secret_key == '' or $secret_key == undef) {
    warning('$secret_key is not specified, thus passwords stored in database are not so securely hashed.')
  }

  if ($database) {
    file { "/etc/${title}/database.json" :
      ensure  => 'present',
      mode    => $config_mode,
      owner   => $user,
      group   => $group,
      content => template('django/database.json.erb'),
      before  => File[$config],
    }
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

  if ($logging) {
    file { "/etc/${title}/logging.json" :
      ensure  => 'present',
      mode    => $config_mode,
      owner   => $user,
      group   => $group,
      content => template('django/logging.json.erb'),
      before  => File[$config],
    }

    file { "/var/log/${title}" :
      ensure => 'directory',
      mode   => '0700',
      owner  => $user,
      group  => $group,
      before => File[$config],
    }
  }

  if ($uwsgi and $uwsgi_chdir and $uwsgi_module and $uwsgi_socket) {
    ::uwsgi::application { $title :
      plugins => 'python',
      uid     => $user,
      gid     => $group,
      socket  => $uwsgi_socket,
      chdir   => $uwsgi_chdir,
      module  => $uwsgi_module,
      vacuum  => $uwsgi_vacuum,
      master  => $uwsgi_master,
      workers => $uwsgi_workers,
      require => [
        Package[$packages],
        User[$user],
      ],
    }
  }
}
