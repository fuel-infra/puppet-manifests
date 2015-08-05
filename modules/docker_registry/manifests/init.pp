# Class: docker_registry
#
class docker_registry (
    $acls,
    $oauth_client_id,
    $oauth_client_secret,
    $oauth_domain,
    $service_fqdn,
    $ssl_certificate_content,
    $ssl_certificate_token_content,
    $ssl_key_content,
    $ssl_key_token_content,
    $anonymous = true,
    $auth_port = 5001,
    $auth_backend_port = 5801,
    $expiration = 900,
    $search_backend_port = 5802,
    $search_password = 'index',
    $search_port = 5002,
    $search_socket = '127.0.0.1:5802',
    $search_user = 'index',
    $server_backend_port = 5800,
    $server_port = 5000,
    $ssl_certificate = '/etc/ssl/certs/registry.crt',
    $ssl_certificate_token = '/etc/registry/token.crt',
    $ssl_key = '/etc/ssl/private/registry.key',
    $ssl_key_token = '/etc/registry/token.key',
    $static_users = {},
) {

  # install requirements
  $packages = [
    'docker-registry',
    'docker-auth',
    'docker-search',
  ]

  ensure_packages($packages)

  # create config files
  file { '/etc/registry/server.yml':
    ensure  => 'file',
    owner   => 'registry',
    group   => 'registry',
    mode    => '0640',
    content => template('docker_registry/server.yml.erb'),
    require => Package[$packages],
  }

  file { '/etc/registry/auth.yml':
    ensure  => 'file',
    owner   => 'registry',
    group   => 'registry',
    mode    => '0640',
    content => template('docker_registry/auth.yml.erb'),
    require => Package[$packages],
  }

  file { '/etc/registry/search.yml':
    ensure  => 'file',
    owner   => 'registry',
    group   => 'registry',
    mode    => '0640',
    content => template('docker_registry/search.yml.erb'),
    require => Package[$packages],
  }

  # create certificate files for Nginx
  file { $ssl_certificate:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_certificate_content,
    require => Package[$packages],
  }

  file { $ssl_key:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_key_content,
    require => Package[$packages],
  }

  # create certificate files for tokens
  file { $ssl_certificate_token:
    ensure  => 'file',
    owner   => 'registry',
    group   => 'registry',
    mode    => '0640',
    content => $ssl_certificate_token_content,
    require => Package[$packages],
  }

  file { $ssl_key_token:
    ensure  => 'file',
    owner   => 'registry',
    group   => 'registry',
    mode    => '0640',
    content => $ssl_key_token_content,
    require => Package[$packages],
  }

  # setup reverse proxies
  ::nginx::resource::vhost { 'auth' :
    ensure              => 'present',
    ssl_port            => $auth_port,
    listen_port         => $auth_port,
    server_name         => [$service_fqdn, $::fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_certificate,
    ssl_key             => $ssl_key,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    proxy               => "https://127.0.0.1:${auth_backend_port}",
    proxy_read_timeout  => 120,
    location_cfg_append => {
      client_max_body_size => '8G',
      proxy_redirect       => 'off',
      proxy_set_header     => {
        'X-Forwarded-For'   => '$remote_addr',
        'X-Forwarded-Proto' => 'https',
        'X-Real-IP'         => '$remote_addr',
        'Host'              => '$host',
      },
    },
    require             => [File[$ssl_key], File[$ssl_certificate]],
  }

  ::nginx::resource::vhost { 'registry' :
    ensure              => 'present',
    listen_port         => $server_port,
    ssl_port            => $server_port,
    server_name         => [$service_fqdn, $::fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_certificate,
    ssl_key             => $ssl_key,
    ssl_cache           => 'shared:SSL:10m',
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    proxy               => "http://127.0.0.1:${server_backend_port}",
    proxy_read_timeout  => 120,
    location_cfg_append => {
      client_max_body_size => '8G',
      proxy_redirect       => 'off',
      proxy_set_header     => {
        'X-Forwarded-For'   => '$remote_addr',
        'X-Forwarded-Proto' => 'https',
        'X-Real-IP'         => '$remote_addr',
        'Host'              => '$host',
      },
    },
    require             => [File[$ssl_key], File[$ssl_certificate]],
  }

  ::nginx::resource::vhost { 'search' :
    ensure              => 'present',
    listen_port         => $search_port,
    server_name         => [$service_fqdn, $::fqdn],
    uwsgi               => $search_socket,
    location_cfg_append => {
      uwsgi_connect_timeout  => '3m',
      uwsgi_read_timeout     => '3m',
      uwsgi_send_timeout     => '3m',
      uwsgi_intercept_errors => 'on',
    },
    require             => Uwsgi::Application['registry-search'],
  }

  # start services and set autostart
  service { 'service-server':
    ensure  => 'running',
    name    => 'docker-registry',
    enable  => true,
    require => [File['/etc/registry/server.yml'],
                File[$ssl_key_token],
                File[$ssl_certificate_token],
                Package[$packages]],
  }

  service { 'service-auth':
    ensure  => 'running',
    name    => 'docker-auth',
    enable  => true,
    require => [File['/etc/registry/auth.yml'],
                File[$ssl_key_token],
                File[$ssl_certificate_token],
                Package[$packages]],
  }

  # setup uwsgi for registry search
  ::uwsgi::application { 'registry-search' :
    plugins        => 'python',
    uid            => 'registry',
    gid            => 'registry',
    socket         => "127.0.0.1:${search_backend_port}",
    enable_threads => true,
    chdir          => '/usr/lib/registry-search',
    module         => 'application',
    require        => Package[$packages],
  }
}
