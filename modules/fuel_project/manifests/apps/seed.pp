# Class: fuel_project::apps::seed
#
# This class deploys Nginx powered http based storage with ability to put
# images from a different locations.
#
# Parameters:
#   [*cron_jobs*] - Cron jobs hiera hash
#     Example:
#       'jenkins-importer':
#         'minute': '*/5'
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
#
class fuel_project::apps::seed (
  $cron_jobs     = {},
  $seed_acl_list = [],
  $shares        = {},
) {

  create_resources(cron, $cron_jobs, {
    ensure => 'present',
  })

  ensure_resource('file', '/var/www', {
    ensure => 'directory',
    owner => 'root',
    group => 'root',
    mode => '0755',
  })

  # include cleaner and get cleanup directories from hiera
  include ::devopslib::downloads_cleaner

  create_resources('::fuel_project::apps::share', $shares, {})

  # FIXME {
  # Backward compability for uploading artefacts via HTTP
  # Should be refactored using rsync+ssh
  #
  if($seed_acl_list != []) {
    include ::fuel_project::nginx
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
    }
  }
  # } FIXME
}
