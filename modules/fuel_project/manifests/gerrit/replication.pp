# Define: fuel_project::gerrit::replication
#
# Replication path consists of:
#   uri: 'user@host:path'
#
# More docs:
# https://gerrit.libreoffice.org/plugins/replication/Documentation/config.html
#
# Parameters:
#   [*host*] - hostname of Gerrit to push to
#   [*path*] - url path to Gerrit to push to
#   [*user*] - user to authenticate with replication target
#   [*auth_group*] - name of a group that the remote should use to access the
#     repositories
#   [*config_file_path*] - configuration file path
#   [*default_force_update*] - allow use force update for project
#   [*mirror*] - remove remote branches that absent locally or invisible to the
#     replication
#   [*private_key*] - private key to use for SSH communication
#   [*projects*] - names of the projects to replicate
#   [*public_key*] - public key to use for SSH communication
#   [*push*] - references to replicate on target repositories
#   [*remote_name_style*] - part of a project name to use as name
#     of a repository on tagert host
#   [*replicate_permissions*] - permissions-only projects and the
#     refs/meta/config branch will also be replicated to the remote site
#   [*replication_delay*] - number of seconds to wait before scheduling a remote
#     push operation
#   [*threads*] - number of worker threads to dedicate to pushing to the
#     repositories described by this remote
#
define fuel_project::gerrit::replication (
  $host,
  $path,
  $user,
  $auth_group            = undef,
  $config_file_path      = '/var/lib/gerrit/review_site/etc/replication.config',
  $default_force_update  = undef,
  $mirror                = undef,
  $private_key           = undef,
  $projects              = undef,
  $public_key            = undef,
  $push                  = undef,
  $remote_name_style     = undef,
  $replicate_permissions = undef,
  $replication_delay     = 0,
  $threads               = 3,
){

  # define replication file
  # Each resource must be uniq otherwise we will have duplicate declaration error,
  # as we are using the SAME configuration file for adding replica points, we must to
  # use ensure_resource which only creates the resource if it does not already exist
  # and thus help us to avoid duplcate declaration problem
  ensure_resource(
    'concat',
    $config_file_path,
    {
      ensure => present,
      owner  => 'gerrit',
      group  => 'gerrit',
      mode   => '0644',
      order  => 'numeric',
      require => [
        Package['gerrit'],
      ],
  })

  # add header with link to docs (to replication file)
  # To avoid duplcate declaration error (because we have concat::fragment, named
  # replication_config_header) we have to use ensure_resource, which only creates
  # the resource if it does not already exist
  ensure_resource(
    'concat::fragment',
    'replication_config_header',
    {
      target  => $config_file_path,
      content => "# This file is managed by puppet.\n#https://gerrit.libreoffice.org/plugins/replication/Documentation/config.html\n",
      order   => '01'
  })

  # add host to known_hosts
  # we can have ${host}-known-hosts multiple times but with different users,
  # so need to be sure for NO DUPLICATION ERROR
  ensure_resource(
    'ssh::known_host',
    "${host}-known-hosts",
    {
      host      => $host,
      user      => 'gerrit',
      overwrite => false,
      require   => User['gerrit'],
  })

  # add ssh key-pare for replication
  # we can have ${user}-${name}-${host} multiple times but with different pathes,
  # so need to be sure for NO DUPLICATION ERROR
  ensure_resource(
    'sshuserconfig::remotehost',
    "${user}-${name}-${host}",
    {
      unix_user           => 'gerrit',
      ssh_config_dir      => '/var/lib/gerrit/.ssh',
      remote_hostname     => $host,
      remote_username     => $user,
      private_key_content => $private_key,
      public_key_content  => $public_key,
  })

  # add replica configuration to gerrrit replication.conf
  # "${user}-${name}-${host}" - MUST be uniq, so failed with duplication error is expected
  concat::fragment { "${user}-${name}-${host}":
    target  => $config_file_path,
    content => template('fuel_project/gerrit/replication.config.erb'),
  }
}
