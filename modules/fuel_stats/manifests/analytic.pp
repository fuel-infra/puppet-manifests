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
  $http_port              = $fuel_stats::params::http_port,
  $https_port             = $fuel_stats::params::https_port,
  $ssl                    = false,
  $ssl_key_file           = '',
  $ssl_cert_file          = '',
  $firewall_enable        = false,
) {
  if $firewall_enable {
    $firewall_rules = hiera_hash('fuel_stats::analytic::firewall_rules', {})
  } else {
    $firewall_rules = {}
  }
  user { 'analytics':
    ensure     => present,
    home       => '/var/www/analytics',
    managehome => false,
    system     => true,
    shell      => '/usr/sbin/nologin',
  }

  file { '/etc/analytics.py':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_stats/analytics.py.erb'),
  }

  if ! defined(File['/var/log/fuel-stats']) {
    file { '/var/log/fuel-stats':
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
  }

  file { '/var/log/fuel-stats/analytics.log':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'analytics',
    group   => 'analytics',
    require => [
      User['analytics'],
      File['/var/log/fuel-stats'],
    ],
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' : }
  }

  if $development {
    $www_root = '/var/www/analytics/analytics/static'
  } else {
    $www_root = '/usr/share/fuel-stats-static/static'
  }

  if $ssl {
    ::nginx::resource::vhost { 'analytics' :
      ensure              => 'present',
      ssl                 => $ssl,
      ssl_port            => $https_port,
      listen_port         => $https_port,
      ssl_cert            => $ssl_cert_file,
      ssl_key             => $ssl_key_file,
      server_name         => [$::fqdn],
      www_root            => $www_root,
      location_cfg_append => $firewall_rules,
    }
    ::nginx::resource::vhost { 'analytics-redirect' :
      ensure              => 'present',
      listen_port         => $http_port,
      www_root            => $www_root,
      server_name         => [$::fqdn],
      location_cfg_append => {
        'rewrite' => "^ https://\$server_name:${https_port}\$request_uri? permanent"
      },
    }
  } else {
    ::nginx::resource::vhost { 'analytics' :
      ensure              => 'present',
      listen_port         => $http_port,
      server_name         => [$::fqdn],
      www_root            => $www_root,
      location_cfg_append => $firewall_rules,
    }
  }

  ::nginx::resource::location { 'analytics-exporter' :
    ensure              => 'present',
    vhost               => 'analytics',
    location            => '/api',
    ssl                 => $ssl,
    ssl_only            => $ssl,
    uwsgi               => '127.0.0.1:7935',
    location_cfg_append => $firewall_rules,
  }

  ::nginx::resource::location { 'analytics-elastic' :
    ensure              => 'present',
    vhost               => 'analytics',
    location            => '~ ^(/fuel)?(/[0-9A-Za-z_]+)?/(_count|_search)',
    ssl                 => $ssl,
    ssl_only            => $ssl,
    proxy               => 'http://127.0.0.1:9200',
    location_cfg_append => $firewall_rules,
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
    # development configuration
    fuel_stats::dev { 'analytics':
      require => User['analytics'],
    }
    uwsgi::application { 'analytics':
      plugins  => 'python',
      uid      => 'analytics',
      gid      => 'analytics',
      socket   => '127.0.0.1:7935',
      env      => 'ANALYTICS_SETTINGS=/etc/analytics.py',
      chdir    => '/var/www/analytics/analytics',
      module   => 'fuel_analytics.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/analytics.py'],
        File['/var/log/fuel-stats/analytics.log'],
        User['analytics'],
        Fuel_stats::Dev['analytics'],
      ],
    }
  } else {
    # production configuration
    package { 'fuel-stats-static' :
      ensure => 'installed',
    }
    package { 'fuel-stats-analytics' :
      ensure => 'installed',
      notify => Service['uwsgi'],
    }
    uwsgi::application { 'analytics':
      plugins  => 'python',
      uid      => 'analytics',
      gid      => 'analytics',
      socket   => '127.0.0.1:7935',
      env      => 'ANALYTICS_SETTINGS=/etc/analytics.py',
      chdir    => '/usr/lib/python2.7/dist-packages',
      module   => 'fuel_analytics.api.app_prod',
      callable => 'app',
      require  => [
        File['/etc/analytics.py'],
        File['/var/log/fuel-stats/analytics.log'],
        User['analytics'],
      ],
    }
  }
}
