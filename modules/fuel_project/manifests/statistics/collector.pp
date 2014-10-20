# Anonymous statistics collector
class fuel_project::statistics::collector (
  $ldap                   = false,
  $development            = false,
  $apply_firewall_rules   = false,
  $psql_user              = 'collector',
  $psql_pass              = 'collector',
  $psql_db                = 'collector',
  $psql_port              = 5432,
  $analytic_ip            = '127.0.0.1',
  $service_port           = 443,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $ssl_key_file           = '/etc/nginx/fuel-collector.key',
  $ssl_key_file_contents  = '',
  $ssl_cert_file          = '/etc/nginx/fuel-collector.crt',
  $ssl_cert_file_contents = '',
) {
  class { '::fuel_project::common':
    ldap => $ldap,
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      apply_firewall_rules => $apply_firewall_rules,
      create_www_dir       => false,
    }
  }

  user { 'collector' :
    ensure     => present,
    home       => '/var/www/collector',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  # nginx configuration
  # /etc/nginx/sites-available/fuel-collector.conf
  # virtual host file for nginx
  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/statistics/fuel-collector.conf.erb'),
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

  file { $ssl_key_file :
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_key_file_contents,
  }

  file { $ssl_cert_file :
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $ssl_cert_file_contents,
  }

  # Postgresql configuration
  if ! defined(Class['postgresql::server']) {
    class { 'postgresql::server' :
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
  postgresql::server::db { $psql_db :
    user     => $psql_user,
    password => postgresql_password($psql_user, $psql_pass),
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
    file { '/var/www/collector' :
      owner   => 'collector',
      group   => 'collector',
      mode    => '0755',
      require => [ Package[$packages], User['collector']],
    }
    exec {'clone-github-collector':
      user        => 'collector',
      command     =>
        "/usr/bin/git clone ${fuel_stats_repo} /var/www/collector",
      refreshonly => true,
      subscribe   => File['/var/www/collector'],
    }
    exec {'fuel-stats-pip':
      command =>
        'pip install -r /var/www/collector/collector/test-requirements.txt',
      path    => '/usr/bin',
      require => Exec['clone-github-collector'],
    }

    # github poller script
    file { '/usr/local/bin/github-poller.py' :
      source => 'puppet:///modules/fuel_project/statistics/github-poller.py',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

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
    # uwsgi configuration
    uwsgi::application { 'collector':
      plugins  => 'python',
      uid      => 'collector',
      gid      => 'collector',
      socket   => '127.0.0.1:7932',
      chdir    => '/var/www/collector/collector',
      module   => 'collector.api.app',
      callable => 'app',
      require  => Exec['clone-github-collector'],
    }
  } else {
    notify { 'Production configuration': }
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    firewall { 'Allow analytic psql connection' :
      ensure  => present,
      source  => "${analytic_ip}/32",
      dport   => $psql_port,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
    firewall { 'Allow https collector connection' :
      ensure  => present,
      dport   => $service_port,
      proto   => 'tcp',
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }

  file { '/var/log/fuel-stats' :
    ensure => 'directory',
    mode   => '0755',
    owner  => 'collector',
    group  => 'collector',
  }
}
