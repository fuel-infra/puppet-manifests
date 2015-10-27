# log_storage::storage::nginx class
#
class log_storage::storage::nginx (
  $nginx_elastic_access_log = '/var/log/nginx/elasticsearch-access.log',
  $nginx_elastic_error_log  = '/var/log/nginx/elasticsearch-error.log',
  $nginx_kibana_access_log  = '/var/log/nginx/kibana-access.log',
  $nginx_kibana_error_log   = '/var/log/nginx/kibana-error.log',
  $nginx_log_format         = undef,
  $oauth_access_file        = '/etc/nginx/oauth-access.lua',
  $oauth_body_filter_file   = '/etc/nginx/oauth-body-filter.lua',
  $oauth_client_id          = '1002312874186-t277tpb8nrlht9f897uri0p8ub9qanep.apps.googleusercontent.com',
  $oauth_client_secret      = 'F4m3S4YwqJLLNzgXzmHEAFd2',
  $oauth_domain             = 'domain.com',
  $oauth_token_secret       = 'HfihgighoghGFjfodfjOJgEwew9pfjoheughfi2wweifoef',
  $ssl_certificate_file     = '/etc/nginx/ssl.crt',
  $ssl_certificate          = $log_storage::params::nginx_ssl_certificate,
  $ssl_key_file             = '/etc/nginx/ssl.key',
  $ssl_key                  = $log_storage::params::nginx_ssl_key,
  $www_root                 = '/var/www/html',
) inherits log_storage::params {

  if ($ssl_certificate and $ssl_key_file) {
    file { $ssl_certificate_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_certificate,
      before  => [
        Nginx::Resource::Vhost['kibana'],
        Nginx::Resource::Vhost['elasticsearch'],
      ]
    }

    file { $ssl_key_file :
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $ssl_key,
      before  => [
        Nginx::Resource::Vhost['kibana'],
        Nginx::Resource::Vhost['elasticsearch'],
      ]
    }

    ::nginx::resource::vhost { 'kibana-redirect' :
      ensure              => 'present',
      server_name         => [$::fqdn],
      listen_port         => 80,
      www_root            => $www_root,
      access_log          => $nginx_access_log,
      error_log           => $nginx_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        return => "301 https://${::fqdn}\$request_uri",
      },
    }

    ::nginx::resource::vhost { 'kibana' :
      ensure                     => 'present',
      listen_port                => 443,
      server_name                => [$::fqdn],
      ssl                        => true,
      ssl_cert                   => $ssl_certificate_file,
      ssl_key                    => $ssl_key_file,
      ssl_cache                  => 'shared:SSL:10m',
      ssl_session_timeout        => '10m',
      ssl_stapling               => true,
      ssl_stapling_verify        => true,
      proxy                      => 'http://127.0.0.1:5601',
      proxy_read_timeout         => 120,
      access_log                 => $nginx_kibana_access_log,
      error_log                  => $nginx_kibana_error_log,
      format_log                 => $nginx_log_format,
      vhost_cfg_append           => {
        access_by_lua_file       => "\"${oauth_access_file}\"",
        'set $ngo_domain'        => "\"${oauth_domain}\"",
        'set $ngo_client_id'     => "\"${oauth_client_id}\"",
        'set $ngo_client_secret' => "\"${oauth_client_secret}\"",
        'set $ngo_token_secret'  => "\"${oauth_token_secret}\"",
      },
      location_cfg_append        => {
        proxy_redirect   => 'off',
        proxy_set_header => {
          'X-Forwarded-For'   => '$remote_addr',
          'X-Forwarded-Proto' => 'https',
          'X-Real-IP'         => '$remote_addr',
          'Host'              => '$host',
        },
      },
      location_custom_cfg_append => {
        header_filter_by_lua    => '"ngx.header.content_length = nil";',
        body_filter_by_lua_file => "\"${oauth_body_filter_file}\";",
      },
    }

    ::nginx::resource::vhost { 'elasticsearch' :
      ensure              => 'present',
      listen_port         => 9201,
      server_name         => [$::fqdn],
      ssl                 => true,
      ssl_cert            => $ssl_certificate_file,
      ssl_key             => $ssl_key_file,
      ssl_cache           => 'shared:SSL:10m',
      ssl_port            => 9201,
      ssl_session_timeout => '10m',
      ssl_stapling        => true,
      ssl_stapling_verify => true,
      proxy               => "http://${::fqdn}:9200",
      proxy_read_timeout  => 120,
      access_log          => $nginx_elastic_access_log,
      error_log           => $nginx_elastic_error_log,
      format_log          => $nginx_log_format,
      location_cfg_append => {
        proxy_redirect   => 'off',
        proxy_set_header => {
          'X-Forwarded-For'   => '$remote_addr',
          'X-Forwarded-Proto' => 'https',
          'X-Real-IP'         => '$remote_addr',
          'Host'              => '$host',
        },
      },
    }
  }
}
