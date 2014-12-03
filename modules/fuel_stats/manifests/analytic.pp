# Anonymous statistics analytic
#
# you should already have cert and key on FS if you want to use ssl
class fuel_stats::analytic (
  $development            = false,
  $auto_update            = false,
  $fuel_stats_repo        = 'https://github.com/stackforge/fuel-stats/',
  $elastic_listen_ip      = '127.0.0.1',
  $elastic_http_port      = '9200',
  $elastic_tcp_port       = '9300',
  $nginx_conf             = '/etc/nginx/sites-available/fuel-analytic.conf',
  $nginx_conf_link        = '/etc/nginx/sites-enabled/fuel-analytic.conf',
  $service_port           = 80,
  $ssl                    = false,
  $ssl_key_file           = '',
  $ssl_cert_file          = '',
  $firewall_enable        = false,
  $firewall_allow_sources = {},
  $firewall_deny_sources  = {},
) {
  user { 'analytic':
    ensure     => present,
    home       => '/var/www/analytic',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' : }
  }

  # nginx configuration
  # /etc/nginx/sites-available/fuel-analytic.conf
  # virtual host file for nginx
  if $development {
    $www_root = '/var/www/analytic/analytics/static'
  } else {
    $www_root = '/usr/share/fuel-stats-analytics/static'
  }

  file { $nginx_conf :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_stats/fuel-analytic.conf.erb'),
    notify  => Service['nginx'],
  }

  # /etc/nginx/sites-enabled/fuel-analytic.conf
  # symlink to activate virtual host configuration for nginx
  file { $nginx_conf_link :
    ensure  => 'link',
    target  => $nginx_conf,
    require => File[$nginx_conf],
    notify  => Service['nginx']
  }

  class { 'elasticsearch':
    manage_repo  => false,
    java_install => true,
    java_package => 'openjdk-7-jre-headless',
    config       => {
      'network.host'       => $elastic_listen_ip,
      'http.port'          => $elastic_http_port,
      'transport.tcp.port' => $elastic_tcp_port,
    },
    require      => Class['apt'],
    notify       => Service['elasticsearch']
  }

  service { 'elasticsearch':
    ensure  => 'running',
    enable  => true,
    require => Class['elasticsearch']
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
      ensure  => 'directory',
      owner   => 'analytic',
      group   => 'analytic',
      mode    => '0755',
      require => [ Package[$packages], User['analytic']],
    }
    exec { 'clone-github-analytic':
      command     =>
        "/usr/bin/git clone ${fuel_stats_repo} /var/www/analytic",
      require     => [ Package[$packages], User['analytic']],
      refreshonly => true,
      subscribe   => File['/var/www/analytic'],
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
        environment => 'REPO_LOCAL=/var/www/analytic',
        user        => 'analytic',
        hour        => '*',
        minute      => '*',
        require     => [
          File['/usr/local/bin/github-poller.py'],
          Exec['clone-github-analytic'],
        ],
      }
    }
  } else {
    package { 'fuel-stats-analytics' :
      ensure => 'installed',
    }
  }
}
