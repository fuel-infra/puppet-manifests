# Class: fuel_project::apps::seed
#
# This class deploys Nginx powered http based storage with ability to put
# images from a different locations.
#
# Parameters:
#   [*seed_acl_list*] - Array, list of hosts to be allowed to connect to nginx
#     upload vhost.
#   [*shares*] - Hash, Describes the share in following form:
#     $shares =  {
#       'mylovelyshare' => {
#         'service_fqdn'        => 'myhost.example.com',
#         'path'                => '/var/www/myshare',
#         'autoindex'           => false,
#         'http_ro'             => true,
#         'ssh_authorized_keys' => {
#           'mykey' => {
#             'type': 'ssh-rsa',
#             'key': '<SSH PUBLIC KEY>'
#           }
#         }
#       }
#     }
#
#     For more parameters please refer to ::fuel_project::apps::share
#
#   [*cleanup_dirs*] - Array, list of hashes contains dirs to clean up
#     pereodically in the following form:
#     $cleanup_dirs = [
#       {
#         'dir'     => '/var/www/dir',
#         'ttl'     => '10' # in days
#         'pattern' => '*.txt'
#       }
#     ]
#
class fuel_project::apps::seed (
  $seed_acl_list,
  $shares = {},
  $cleanup_dirs = [],
) {
  ensure_resource('file', '/var/www', {
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '0755',
  })

  class {'::devopslib::downloads_cleaner' :
    cleanup_dirs => $cleanup_dirs,
  }

  create_resources('::fuel_project::apps::share', $shares, {})

  # FIXME {
  # Backward compability for uploading artefacts via HTTP
  # Should be refactored using rsync+ssh
  #
  ::nginx::resource::vhost { 'seed-upload' :
    ensure              => 'present',
    autoindex           => 'off',
    www_root            => '/var/www/seed',
    listen_port         => '17333',
    server_name         => [$::fqdn],
    access_log          => '/var/log/nginx/access.log',
    error_log           => '/var/log/nginx/error.log',
    format_log          => 'proxy',
    location_cfg_append => {
      dav_methods          => 'PUT',
      client_max_body_size => '5G',
      allow                => $seed_acl_list,
      deny                 => 'all',
      disable_symlinks     => 'if_not_owner',
    },
    require             => Class['fuel_project::nginx'],
  }
  # } FIXME
}
