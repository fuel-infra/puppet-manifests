#
class fuel_project::fuel_docs(
  $community_hostname           = 'docs.fuel-infra.org',
  $community_ssl_cert_content   = '',
  $community_ssl_cert_filename  = '/etc/ssl/community-docs.crt',
  $community_ssl_key_content    = '',
  $community_ssl_key_filename   = '/etc/ssl/community-docs.key',
  $docs_user                    = 'docs',
  $firewall_enable              = false,
  $fuel_version                 = '6.0',
  $hostname                     = 'docs.mirantis.com',
  $redirect_root_to             = 'http://www.mirantis.com/openstack-documentation/',
  $nginx_access_log             = '/var/log/nginx/access.log',
  $nginx_error_log              = '/var/log/nginx/error.log',
  $nginx_log_format             = undef,
  $ssh_auth_key                 = undef,
  $ssl_cert_content             = '',
  $ssl_cert_filename            = '/etc/ssl/docs.crt',
  $ssl_key_content              = '',
  $ssl_key_filename             = '/etc/ssl/docs.key',
  $www_root                     = '/var/www'
) {
  class { '::fuel_project::common' :
    external_host => $firewall_enable,
  }

  user { $docs_user :
    ensure     => 'present',
    shell      => '/bin/bash',
    managehome => true,
  }

  if ($ssl_cert_content and $ssl_key_content) {
    file { $ssl_cert_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $ssl_cert_content,
    }
    file { $ssl_key_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $ssl_key_content,
    }
    Nginx::Resource::Vhost <| title == $hostname |> {
      ssl         => true,
      ssl_cert    => $ssl_cert_filename,
      ssl_key     => $ssl_key_filename,
      listen_port => 443,
      ssl_port    => 443,
    }
    ::nginx::resource::vhost { "${hostname}-redirect" :
      ensure              => 'present',
      server_name         => [$hostname],
      listen_port         => 80,
      www_root            => $www_root,
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${hostname}\$request_uri",
      },
    }
    $ssl = true
  } else {
    $ssl = false
  }

  if ($community_ssl_cert_content and $community_ssl_key_content) {
    file { $community_ssl_cert_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $community_ssl_cert_content,
    }
    file { $community_ssl_key_filename :
      ensure  => 'present',
      mode    => '0600',
      group   => 'root',
      owner   => 'root',
      content => $community_ssl_key_content,
    }
    Nginx::Resource::Vhost <| title == $community_hostname |> {
      ssl         => true,
      ssl_cert    => $community_ssl_cert_filename,
      ssl_key     => $community_ssl_key_filename,
      listen_port => 443,
      ssl_port    => 443,
    }
    ::nginx::resource::vhost { "${community_hostname}-redirect" :
      ensure              => 'present',
      server_name         => [$community_hostname],
      listen_port         => 80,
      www_root            => $www_root,
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${community_hostname}\$request_uri",
      },
    }
    $community_ssl = true
  } else {
    $community_ssl = false
  }

  if ($ssh_auth_key) {
    ssh_authorized_key { 'fuel_docs@jenkins' :
      user    => $docs_user,
      type    => 'ssh-rsa',
      key     => $ssh_auth_key,
      require => User[$docs_user],
    }
  }

  class { '::fuel_project::nginx' : }

  ::nginx::resource::vhost { $community_hostname :
    ensure              => 'present',
    server_name         => [$community_hostname],
    listen_port         => 80,
    www_root            => $www_root,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      'rewrite' => {
        '^/$'                => '/fuel-dev',
        '^/express/?$'       => '/openstack/express/latest',
        '^/(express/.+)'     => '/openstack/$1',
        '^/fuel/?$'          => "/openstack/fuel/fuel-${fuel_version}",
        '^/(fuel/.+)'        => '/openstack/$1',
        '^/openstack/fuel/$' => "/openstack/fuel/fuel-${fuel_version}",
      },

    }
  }

  ::nginx::resource::location { "${community_hostname}/fuel-dev" :
    vhost          => $community_hostname,
    location       => '/fuel-dev',
    location_alias => "${www_root}/fuel-dev-docs/fuel-dev-master",
    ssl            => $community_ssl,
    ssl_only       => $community_ssl,
  }

  ::nginx::resource::vhost { $hostname :
    ensure              => 'present',
    server_name         => [$hostname],
    listen_port         => 80,
    www_root            => $www_root,
    access_log          => $nginx_access_log,
    error_log           => $nginx_error_log,
    format_log          => $nginx_log_format,
    location_cfg_append => {
      'rewrite' => {
        '^/$'                => $redirect_root_to,
        '^/express/?$'       => '/openstack/express/latest',
        '^/(express/.+)'     => '/openstack/$1',
        '^/fuel/?$'          => "/openstack/fuel/fuel-${fuel_version}",
        '^/(fuel/.+)'        => '/openstack/$1',
        '^/openstack/fuel/$' => "/openstack/fuel/fuel-${fuel_version}",
      },
    }
  }

  ::nginx::resource::location { "${hostname}/fuel-dev" :
    vhost          => $hostname,
    location       => '/fuel-dev',
    location_alias => "${www_root}/fuel-dev-docs/fuel-dev-master",
    ssl            => $ssl,
    ssl_only       => $ssl,
  }


  if (! defined(File[$www_root])) {
    file { $www_root :
      ensure  => 'directory',
      mode    => '0755',
      owner   => $docs_user,
      group   => $docs_user,
      require => User[$docs_user],
    }
  } else {
    File <| title == $www_root |> {
      owner   => $docs_user,
      group   => $docs_user,
      require => User[$docs_user],
    }
  }

  file { "${www_root}/robots.txt" :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/fuel_docs/robots.txt.erb'),
    require => File[$www_root],
  }

  if ($firewall_enable) {
    include firewall_defaults::pre
    firewall { '1000 - allow http/https traffic' :
      dport   => [80, 443],
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    }
  }
}
