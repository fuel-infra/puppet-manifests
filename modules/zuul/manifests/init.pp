# == Class zuul
#
class zuul (
  $dir              = '/usr/share/zuul/public_html',
  $dir_group        = 'www-data',
  $dir_owner        = 'www-data',
  $nginx_access_log = '/var/log/nginx/zuul-access.log',
  $nginx_error_log  = '/var/log/nginx/zuul-error.log',
  $nginx_log_format = 'proxy',
  $service_fqdn     = 'zuul.local',
  $packages         = [
    'nginx',
    'zuul',
  ],
) {

  ensure_resource('user', $dir_owner, {
    ensure => 'present',
  })

  ensure_resource('group', $dir_group, {
    ensure => 'present',
  })

  ensure_packages($packages)

  file { $dir :
    ensure  => 'directory',
    owner   => $dir_owner,
    group   => $dir_group,
    mode    => '0755',
    require => [
        Class['nginx'],
        User[$dir_owner],
        Group[$dir_group],
      ],
  }

  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  # zuul configuration for nginx adopted from
  # https://github.com/openstack-infra/puppet-zuul/blob/master/templates/zuul.vhost.erb
  ::nginx::resource::vhost { 'zuul_status' :
    ensure      => 'present',
    www_root    => $dir,
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
    server_name => [
      $service_fqdn,
      "zuul.${::fqdn}",
    ],
  }

  ::nginx::resource::location { 'status.json' :
    ensure   => 'present',
    location => '/status.json',
    vhost    => 'zuul_status',
    proxy    => 'http://127.0.0.1:8001/status.json',
  }

  # Correctly use matching for zuul status targeted pass through so that
  # we can get the optimized per change zuul results.
  ::nginx::resource::location { 'status' :
    ensure   => 'present',
    location => '~ ^/status/(.*)',
    vhost    => 'zuul_status',
    proxy    => 'http://127.0.0.1:8001/status/$1',
  }

}
