# Class: docker_registry
#
# This class deploys fully functional Docker Registry instance with multiple
# additional features:
#
# Docker Registry API - provides a required access for Docker clients to
# fetch images. Opened for all IP addresses connections. Required for users to
# push debug images.
#
# Docker Authorization API - provides an authorization method for the main
# registry API. Opened for all IP addresses connections. Required for users to
# authorized when pushing debug images.
#
# Docker Search API - provides a list of images available on Docker registry.
# Very simple service which allows to send queries about available images on
# registry.
#
# Parameters:
#   [*acls*] - hash of acl values:
#     # Admin has full access to everything.
#     'account: "admin"': '*'
#     # Jenkins has full access to everything.
#     'account: "jenkins"': '*'
#     # Index has full access to everything.
#     'account: "index", name: "catalog"': '*'
#     # All logged in users can pull all images.
#     'account: "/.+/"': 'pull'
#     # Anynoymous users can pull all images.
#     'account: ""': 'pull'
#     # Access is denied by default.
#
#      ACL specifies who can do what. If the match section of an entry matches the
#      request, the set of allowed actions will be applied to the token request
#      and a ticket will be issued only for those of the requested actions that are
#      allowed by the rule.
#       * It is possible to match on user's name ("account"), subject type ("type")
#         and name ("name"; for type=repository which, at the timeof writing, is the
#         only known subject type, this is the image name).
#       * Matches are evaluated as shell file name patterns ("globs") by default,
#         so "foobar", "f??bar", "f*bar" are all valid. For even more flexibility
#         match patterns can be evaluated as regexes by enclosing them in //, e.g.
#         "/(foo|bar)/".
#       * IP match can be single IP address or a subnet in the "prefix/mask" notation.
#       * ACL is evaluated in the order it is defined until a match is found.
#       * Empty match clause matches anything, it only makes sense at the end of the
#         list and can be used as a way of specifying default permissions.
#       * Empty actions set means "deny everything". Thus, a rule with `actions: []`
#         is in effect a "deny" rule.
#       * A special set consisting of a single "*" action means "allow everything".
#       * If no match is found the default is to deny the request.
#
#      You can use the following variables from the ticket request in any field:
#       * ${account} - the account name, currently the same as authenticated user's name.
#       * ${service} - the service name, specified by auth.token.service in the registry config.
#       * ${type} - the type of the entity, normally "repository".
#       * ${name} - the name of the repository (i.e. image), e.g. centos.
#
#   [*oauth_client_id*] - client id from Google OAuth
#   [*oauth_client_secret*] - client secret from Google OAuth
#   [*oauth_domain*] - domain used in Google OAuth
#   [*service_fqdn*] - server main FQDN used in many redirection and virtual hosts
#   [*ssl_certificate_global_content*] - main domain certificate content
#   [*ssl_certificate_internal_content*] - host fqdn domain certificate content
#   [*ssl_certificate_token_content*] - token generator certificate content
#   [*ssl_key_global_content*] - main domain key content
#   [*ssl_key_internal_content*] - host fqdn domain key content
#   [*ssl_key_token_content*] - token generator key content
#   [*anonymous*] - create anonymous account
#   [*auth_port*] - authorization service port
#   [*auth_backend_port*] - authorization service backend port
#   [*expiration*] - token expiration time (in seconds)
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
#   [*static_users*] - static users hash, example:
#     'admin': '$2y$05$ab6e4vb/.rR8R0nip0oro.VMrgq29Rl32WCEDE/fgHemeA22jARnq'
#     'index': '$2y$05$SAHQikfd8Ku6WYf9Ok4Fz.m7MUVHWHIunEctOcahhpwWpl4rgyNx2'
#     'jenkins': '$2y$05$XaoxJINyRxHkrmRkV9NVjuLBSLJ5EGwG16bpusObEDi8eD4pegCsy'
#
class docker_registry (
    $acls,
    $oauth_client_id,
    $oauth_client_secret,
    $oauth_domain,
    $service_fqdn,
    $ssl_certificate_global_content,
    $ssl_certificate_internal_content,
    $ssl_certificate_token_content,
    $ssl_key_global_content,
    $ssl_key_internal_content,
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
    $server_port = 443,
    $ssl_certificate_global = '/etc/ssl/certs/registry.crt',
    $ssl_certificate_internal = '/etc/ssl/certs/internal.crt',
    $ssl_certificate_token = '/etc/registry/token.crt',
    $ssl_key_global = '/etc/ssl/private/registry.key',
    $ssl_key_internal = '/etc/ssl/private/internal.key',
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

  # create certificate files for global Nginx
  file { $ssl_certificate_global:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_certificate_global_content,
    require => Package[$packages],
  }

  file { $ssl_key_global:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_key_global_content,
    require => Package[$packages],
  }

  # create certificate files for internal Nginx
  file { $ssl_certificate_internal:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_certificate_internal_content,
    require => Package[$packages],
  }

  file { $ssl_key_internal:
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $ssl_key_internal_content,
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
    server_name         => [$service_fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_certificate_global,
    ssl_key             => $ssl_key_global,
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
    require             => [File[$ssl_key_global], File[$ssl_certificate_global]],
  }

  ::nginx::resource::vhost { 'registry-global' :
    ensure              => 'present',
    listen_port         => $server_port,
    ssl_port            => $server_port,
    server_name         => [$service_fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_certificate_global,
    ssl_key             => $ssl_key_global,
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
    require             => [File[$ssl_key_global], File[$ssl_certificate_global]],
  }

  ::nginx::resource::vhost { 'registry-internal' :
    ensure              => 'present',
    listen_port         => $server_port,
    ssl_port            => $server_port,
    server_name         => [$::fqdn],
    ssl                 => true,
    ssl_cert            => $ssl_certificate_internal,
    ssl_key             => $ssl_key_internal,
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
