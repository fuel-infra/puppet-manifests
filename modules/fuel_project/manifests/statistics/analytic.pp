# Anonymous statistics analytic
class fuel_project::statistics::analytic (
  $development            = false,
  $commercial             = false,
  $service_port           = 443,
  $apply_firewall_rules   = false,
  $firewall_allow_sources = {},
  $ldap                   = false,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-collector.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-collector.conf',
  $ssl_key_file           = '',
  $ssl_key_file_contents  = '',
  $ssl_cert_file          = '',
  $ssl_cert_file_contents = '',
) {
  class { '::fuel_project::common':
    ldap => $ldap,
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :
      apply_firewall_rules => $apply_firewall_rules,
      create_www_dir       => true,
    }
  }

  user { 'analytic' :
    ensure     => present,
    home       => '/var/www/analytic',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
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

  # nginx configuration
  # /etc/nginx/sites-available/fuel-analytic.conf
  # virtual host file for nginx
  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/statistics/fuel-analytic.conf.erb'),
    require => Class['nginx'],
  }

  # /etc/nginx/sites-enabled/fuel-analytic.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure  => 'link',
    target  => $nginx_conf,
    require => File[$nginx_conf],
    notify  => Service['nginx']
  }

  $packages = [
    'elasticsearch',
    'openjdk-7-jre-headless',
  ]

  ensure_packages($packages, {
    require => Class['apt']
  })

  file { '/etc/elasticsearch/elasticsearch.yml' :
    ensure  => 'present',
    content => template('fuel_project/statistics/elasticsearch.yml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['elasticsearch']
  }

  service { 'elasticsearch' :
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => false,
    require    => [
      Package[$packages],
      File['/etc/elasticsearch/elasticsearch.yml'],
    ]
  }


  if $development {
    $dev_packages = [
      'python-pip',
      'git',
      'libpq-dev',
      'libpython-dev',
      'python-git', # github-poller.py
    ]
    ensure_packages($dev_packages)
    file { '/var/www/analytic' :
      owner   => 'analytic',
      group   => 'analytic',
      mode    => '0755',
      require => [ Package[$packages], User['analytic']],
    }
    exec { 'clone-github-analytic' :
      command     =>
        "/usr/bin/git clone ${fuel_stats_repo} /var/www/analytic",
      require     => [ Package[$packages], User['analytic']],
      refreshonly => true,
      subscribe   => File['/var/www/analytic'],
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
      environment => 'REPO_LOCAL=/var/www/analytic',
      user        => 'analytic',
      hour        => '*',
      minute      => '*',
      require     => [
        File['/usr/local/bin/github-poller.py'],
        Exec['clone-github-analytic'],
      ],
    }
  } else {
    notify { 'Production configuration': }
  }

  if ($apply_firewall_rules) {
    include firewall_defaults::pre
    if ($commercial) {
      create_resources(firewall, $firewall_allow_sources, {
        ensure  => present,
        port    => [80, $service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      })
    } else {
      firewall { 'Allow http and https collector connection' :
        ensure  => present,
        port    => [80, $service_port],
        proto   => 'tcp',
        action  => 'accept',
        require => Class['firewall_defaults::pre'],
      }
    }
  }

}
