# Class: devops
#
class devops (
  $install_cron_cleanup = true,
  $psql_user   = 'devops',
  $psql_pass   = 'devops',
  $psql_db     = 'devops',
  $psql_engine = 'django.db.backends.postgresql_psycopg2',
  $psql_host   = '127.0.0.1',
  $psql_port   = '',
) {

  if ! defined(Class['postgresql::server']) {
    class { 'postgresql::server' : }
  }

  postgresql::server::db { $psql_db :
    user     => $psql_user,
    password => postgresql_password($psql_user, $psql_pass),
  }

  if ! defined(Package['python-devops']) {
    package { 'python-devops' :
      ensure => installed,
    }
  }

  exec { 'devops-syncdb' :
    command   => '/usr/bin/django-admin syncdb --settings=devops.settings',
    logoutput => on_failure,
    require   =>  [ Postgresql::Server::Db[$psql_db],
                    Package['python-devops'],
                    File['/usr/lib/python2.7/dist-packages/devops/local_settings.py'],
                  ],
  }

  exec { 'devops-migrate' :
    command   => '/usr/bin/django-admin migrate devops --settings=devops.settings',
    logoutput => on_failure,
    require   =>  [ Postgresql::Server::Db[$psql_db],
                    Package['python-devops'],
                    File['/usr/lib/python2.7/dist-packages/devops/local_settings.py'],
                    Exec['devops-syncdb'],
                  ],
  }

  file { '/etc/devops' :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/devops/local_settings.py' :
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('devops/devops_local_settings.py.erb'),
    require => File['/etc/devops']
  }

  file { '/usr/lib/python2.7/dist-packages/devops/local_settings.py' :
    ensure  => link,
    target  => '/etc/devops/local_settings.py',
    require => File['/etc/devops/local_settings.py'],
  }

  if $install_cron_cleanup {
    file { 'devops-env-cleanup.sh' :
      path    => '/usr/local/bin/devops-env-cleanup.sh',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('devops/devops-env-cleanup.sh.erb'),
    }

    cron { 'devops-env-cleanup' :
      command => '/usr/local/bin/devops-env-cleanup.sh 2>&1 | logger -t devops-env-cleanup',
      user    => root,
      hour    => 16, # 16:00 UTC
      minute  => 0,
    }
  }
}
