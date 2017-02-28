# Class: registry
#
# This class deploys fully functional Docker Registry instance with multiple
# additional features:
#
# Docker Registry API - provides a required access for Docker clients to
# fetch images. Opened for all IP addresses connections. Required for users to
# push debug images.
#
# Docker Search API - provides a list of images available on Docker registry.
# Very simple service which allows to send queries about available images on
# registry.
#
# Parameters:
#   [*htpasswd_content*] - htaccess file content with users authorized to push images
#   [*service_fqdn*] - server main FQDN used in many redirection and virtual hosts
#   [*ssl_certificate_global_content*] - main domain certificate content
#   [*ssl_certificate_internal_content*] - host fqdn domain certificate content
#   [*ssl_certificate_token_content*] - token generator certificate content
#   [*ssl_key_global_content*] - main domain key content
#   [*ssl_key_internal_content*] - host fqdn domain key content
#   [*ssl_key_token_content*] - token generator key content
#   [*anonymous*] - create anonymous account
#   [*config_search*] - path to search server configuration file
#   [*config_server*] - path to docker registry server configuration file
#   [*expiration*] - token expiration time (in seconds)
#   [*htpasswd_path*] - path to htaccess file with users authorized to push images
#   [*rw_addresses*] - list of CIDR IPv4 addresses which does not need authorization
#   [*search_backend_port*] - search service backend port
#   [*search_password*] - docker registry account password used by search daemon to index
#   [*search_port*] - search service port
#   [*search_socket*] - socket where search service is listening
#   [*search_user*] - docker registry account password used by search daemon to index
#   [*server_backend_port*] - docker registry backend port
#   [*server_port*] - docker registry port
#   [*ssl_certificate_global*] - main domain certificate
#   [*ssl_certificate_internal*] - host fqdn domain certificate
#   [*ssl_certificate_token*] - token generator certificate
#   [*ssl_key_global*] - main domain key
#   [*ssl_key_internal*] - host fqdn domain key
#   [*ssl_key_token*] - token generator key
#
class registry (
    $htpasswd_content,
    $service_fqdn,
    $ssl_certificate_global_content,
    $ssl_certificate_internal_content,
    $ssl_certificate_token_content,
    $ssl_key_global_content,
    $ssl_key_internal_content,
    $ssl_key_token_content,
    $anonymous = true,
    $config_search = '/etc/docker/registry/search.yml',
    $config_server = '/etc/docker/registry/config.yml',
    $expiration = 900,
    $htpasswd_path = '/etc/nginx/conf.d/registry.htpasswd',
    $rw_addresses = [],
    $search_backend_port = 5802,
    $search_password = 'index',
    $search_port = 5002,
    $search_socket = '127.0.0.1:5802',
    $search_user = 'index',
    $server_backend_port = 5800,
    $server_port = 443,
    $service_group = 'docker-registry',
    $service_user = 'docker-registry',
    $ssl_certificate_global = '/etc/ssl/certs/registry.crt',
    $ssl_certificate_internal = '/etc/ssl/certs/internal.crt',
    $ssl_certificate_token = '/etc/docker/registry/token.crt',
    $ssl_key_global = '/etc/ssl/private/registry.key',
    $ssl_key_internal = '/etc/ssl/private/internal.key',
    $ssl_key_token = '/etc/docker/registry/token.key',
) {
  include ::nginx

  ensure_packages(['docker-registry','docker-search'])

  # create config files
  file { $config_server:
    ensure  => 'file',
    owner   => $service_user,
    group   => $service_group,
    mode    => '0640',
    content => template('registry/config.yml.erb'),
    require => Package['docker-registry'],
  }

  file { $config_search:
    ensure  => 'file',
    owner   => $service_user,
    group   => $service_group,
    mode    => '0640',
    content => template('registry/search.yml.erb'),
    require => Package['docker-search'],
  }

  # create file with htpasswd entries
  file { $htpasswd_path:
    ensure  => 'file',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0640',
    content => $htpasswd_content,
    require => Package['nginx-full'],
  }

  # create certificate files for global Nginx
  file { $ssl_certificate_global:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_certificate_global_content,
    require => Package['nginx-full'],
  }

  file { $ssl_key_global:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_key_global_content,
    require => Package['nginx-full'],
  }

  # create certificate files for internal Nginx
  file { $ssl_certificate_internal:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_certificate_internal_content,
    require => Package['nginx-full'],
  }

  file { $ssl_key_internal:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_key_internal_content,
    require => Package['nginx-full'],
  }

  # create certificate files for tokens
  file { $ssl_certificate_token:
    ensure  => 'file',
    owner   => $service_user,
    group   => $service_group,
    mode    => '0640',
    content => $ssl_certificate_token_content,
    require => Package['nginx-full'],
  }

  file { $ssl_key_token:
    ensure  => 'file',
    owner   => $service_user,
    group   => $service_group,
    mode    => '0640',
    content => $ssl_key_token_content,
    require => Package['nginx-full'],
  }

  # schedule garbage-collector runs
  cron { 'garbage-collect':
    command => "/usr/bin/docker-registry garbage-collect ${config_server}",
    user    => $service_user,
    hour    => 3,
    minute  => 0,
  }

  ::nginx::resource::vhost { 'registry-global' :
    ensure              => 'present',
    listen_port         => $server_port,
    location_cfg_append => {
      client_max_body_size => '8G',
      proxy_redirect       => 'off',
      proxy_set_header     => {
        'X-Forwarded-Proto' => '$scheme',
      },
    },
    location_raw_append => template('registry/global-location.erb'),
    proxy               => "http://127.0.0.1:${server_backend_port}",
    proxy_read_timeout  => 120,
    server_name         => [$service_fqdn],
    ssl                 => true,
    ssl_cache           => 'shared:SSL:10m',
    ssl_cert            => $ssl_certificate_global,
    ssl_key             => $ssl_key_global,
    ssl_port            => $server_port,
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    require             => [
      File[$ssl_key_global],
      File[$ssl_certificate_global]
    ],
  }

  ::nginx::resource::vhost { 'registry-internal' :
    ensure              => 'present',
    listen_port         => $server_port,
    location_cfg_append => {
      add_header           => 'Docker-Distribution-Api-Version registry/2.0 always',
      client_max_body_size => '8G',
      proxy_redirect       => 'off',
      proxy_set_header     => {
        'X-Forwarded-Proto' => '$scheme',
      },
    },
    location_raw_append => template('registry/internal-location.erb'),
    proxy               => "http://127.0.0.1:${server_backend_port}",
    proxy_read_timeout  => 120,
    server_name         => [$::fqdn],
    ssl                 => true,
    ssl_cache           => 'shared:SSL:10m',
    ssl_cert            => $ssl_certificate_internal,
    ssl_key             => $ssl_key_internal,
    ssl_port            => $server_port,
    ssl_session_timeout => '10m',
    ssl_stapling        => true,
    ssl_stapling_verify => true,
    require             => [File[$ssl_key_internal], File[$ssl_certificate_internal]],
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
    require             => [
      Uwsgi::Application['registry-search'],
    ]
  }

  # start services and set autostart
  service { 'service-server':
    ensure  => 'running',
    name    => 'docker-registry',
    enable  => true,
    require => [File[$config_server],
                File[$ssl_key_token],
                File[$ssl_certificate_token],
                Package['docker-registry']],
  }

  # setup uwsgi for registry search
  ::uwsgi::application { 'registry-search' :
    plugins        => 'python',
    uid            => $service_user,
    gid            => $service_group,
    socket         => "127.0.0.1:${search_backend_port}",
    enable_threads => true,
    chdir          => '/usr/lib/registry-search',
    module         => 'application',
    require        => Package['docker-search'],
  }
}
