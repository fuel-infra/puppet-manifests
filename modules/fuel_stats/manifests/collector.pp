# Anonymous statistics collector
class fuel_stats::collector (
  $development            = $fuel_stats::params::development,
  $auto_update            = $fuel_stats::params::auto_update,
  $fuel_stats_repo        = $fuel_stats::params::fuel_stats_repo,
  $psql_user              = $fuel_stats::params::psql_user,
  $psql_pass              = $fuel_stats::params::psql_pass,
  $psql_db                = $fuel_stats::params::psql_db,
  $analytic_ip            = '127.0.0.1',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $service_port           = $fuel_stats::params::service_port,
  $ssl_key_file           = '',
  $ssl_key_file_contents  = '',
  $ssl_cert_file          = '',
  $ssl_cert_file_contents = '',
  $firewall_enable        = $fuel_stats::params::firewall_enable,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
) inherits fuel_stats::params {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      apply_firewall_rules => $firewall_enable,
      create_www_dir       => false,
    }
  }

  # nginx configuration
  # /etc/nginx/sites-available/fuel-collector.conf
  # virtual host file for nginx
  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_stats/fuel-collector.conf.erb'),
    require => Class['nginx'],
    notify  => Service['nginx']
  }

  # /etc/nginx/sites-enabled/fuel-collector.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure  => 'link',
    target  => $nginx_conf,
    require => File[$nginx_conf],
    notify  => Service['nginx']
  }

  if $ssl_key_file != '' {
    file { $ssl_key_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key_file_contents,
      require => Package['nginx']
    }
  }

  if $ssl_cert_file != '' {
    file { $ssl_cert_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_cert_file_contents,
      require => Package['nginx']
    }
  }

  user { 'collector':
    ensure     => present,
    home       => '/var/www/collector',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }


  # Postgresql configuration
  if ! defined(Class['postgresql::server']) {
    class { 'postgresql::server':
      listen_addresses           => '*',
      ip_mask_deny_postgres_user => '0.0.0.0/0',
      ip_mask_allow_all_users    => "${analytic_ip}/32",
      ipv4acls                   => [
        "hostssl ${psql_db} ${psql_user} ${analytic_ip}/32 cert",
        "host ${psql_db} ${psql_user} 127.0.0.1/32 md5",
        "local ${psql_db} ${psql_user} md5",
      ],
    }
  }
  postgresql::server::db { $psql_db:
    user     => $psql_user,
    password => postgresql_password($psql_user, $psql_pass),
  }

  file { '/etc/collector.py':
    ensure  => 'file',
    content => template('fuel_stats/collect.py.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  if $development {
    $packages = [
      'python-pip',
      'git',
      'libpq-dev',
      'libpython-dev',
      'python-git', # github-poller.py
    ]

    ensure_packages($packages)
    file { '/var/www/collector':
      ensure  => 'directory',
      owner   => 'collector',
      group   => 'collector',
      mode    => '0755',
      require => [ Package[$packages], User['collector']],
    }
    exec {'clone-github-collector':
      command     =>
        "/usr/bin/git clone ${fuel_stats_repo} /var/www/collector",
      user        => 'collector',
      refreshonly => true,
      subscribe   => File['/var/www/collector'],
    }
    exec {'fuel-collector-pip':
      command =>
        '/usr/bin/pip install -r /var/www/collector/collector/requirements.txt',
      user    => 'root',
      require => Exec['clone-github-collector'],
    }

    # github poller script
    file { '/usr/local/bin/github-poller.py':
      source => 'puppet:///modules/fuel_stats/github-poller.py',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    if ($auto_update) {
      # cronjob
      cron { 'github-poller':
        command     =>
          'flock -n -x /tmp/github-poller.lock /usr/local/bin/github-poller.py',
        environment => 'REPO_LOCAL=/var/www/collector',
        user        => 'collector',
        hour        => '*',
        minute      => '*',
        require     => [
          File['/usr/local/bin/github-poller.py'],
          Exec['clone-github-collector'],
        ],
      }
    }
    # uwsgi configuration
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      env      => 'COLLECTOR_SETTINGS=/etc/collector.py',
      chdir    => '/var/www/collector/collector',
      module   => 'collector.api.app_test',
      callable => 'app',
      require  => Exec['clone-github-collector'],
    }
  } else {
    package { 'fuel-stats-collector' :
      ensure => 'installed',
    }
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      chdir    => '/usr/lib/python2.7/dist-packages',
      module   => 'collector.api.app_prod',
      callable => 'app',
  }
}

  file { '/var/log/fuel-stats':
    ensure => 'directory',
    mode   => '0755',
    owner  => 'collector',
    group  => 'collector',
  }
}
