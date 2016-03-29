# Class: nodepool
#
# This class deploys Nodepool instance.
#
# Parameters:
# [*cron_jobs*] - hash for creating cron jobs
# [*config_dir*] - Nodepools config directory path
# [*dib_cache_dir*] - Used for storage of d-i-b cached data
# [*dib_dir*] - Used for storage of d-i-b images in non-ephemeral partition
# [*dib_tmp_dir*] - Used as TMPDIR during d-i-b image builds
# [*elements_dir*] - Nodepools elements config dir path
# [*environment*] - Additional shell environments to be used with Nodepool
# [*enable_image_log_via_http*] - Enable sharing of image logs via http
# [*image_log_document_root*] - Root path where to store image logs
# [*known_hosts*] - List of hosts which ssh fingerprint key should be added into known_hosts file
# [*logging_conf_hash*] - Hash keys used to configure nodepools logging.conf
# [*nodepool_ssh_private_key_contents*] - Nodepools private key used for auth
# [*project_config_cfg_dir*] - Project-config root directory
# [*project_config_clone_ssh_key_file*] - SSH private file content for the user which has rights accessint the project-config repo.
# [*project_config_clone_ssh_key_file_path*] - Path to ssh private key which stores key used for accessing the project-config repo.
# [*project_config_cron_jobs*] - hash for creating cron jobs
# [*project_config_known_hosts*] - List of hosts which ssh fingerprint key should be added into known_hosts file
# [*project_config_nodepool_yaml_path*] - Nodepool.yaml file path in project-config dir
# [*project_config_repo*] - Url to the project-config repo
# [*project_config_repo_revision*] - Revision to use during the project-repo cloning
# [*project_config_sync_script_path*] - Path to the script which fetches project-config's repository
# [*project_config_user*] - Username to use when cloning project-config repo
# [*scripts_dir*] - Nodepools scripts dir
# [*service_fqdn*] - the FQDN under which host the service
# [*statsd_host*] - The statsd host address to use
# [*statsd_port*] - The statsd port number to use
# [*user*] - Nodepools user to use
#
class nodepool (
  $nodepool_ssh_private_key_contents,
  $config_dir                             = '/etc/nodepool',
  $cron_jobs                              = undef,
  $daemon_args                            = '-c /etc/nodepool/nodepool.yaml -l /etc/nodepool/logging.conf',
  $dib_cache_dir                          = '/var/cache/nodepool_dib_cache',
  $dib_dir                                = '/var/lib/nodepool/dib',
  $dib_tmp_dir                            = '/var/tmp/nodepool_dib_tmp',
  $elements_dir                           = undef,
  $enable_image_log_via_http              = true,
  $environment                            = {},
  $image_log_document_root                = '/var/www/nodepool/image',
  $known_hosts                            = undef,
  $logging_conf_hash                      = {},
  $mysql_db_name                          = 'nodepool',
  $mysql_host                             = '127.0.0.1',
  $project_config_cfg_dir                 = '/etc/project-config',
  $project_config_clone_ssh_key_file      = undef,
  $project_config_clone_ssh_key_file_path = '/var/lib/project-config-cloner/.ssh/id_rsa',
  $project_config_cron_jobs               = undef,
  $project_config_known_hosts             = undef,
  $project_config_nodepool_yaml_path      = '/etc/project-config/nodepool/nodepool.yaml',
  $project_config_repo                    = 'https://git.example.com/project-config',
  $project_config_repo_revision           = 'master',
  $project_config_sync_script_path        = '/usr/local/bin/project_config_sync.sh',
  $project_config_user                    = 'project-config-cloner',
  $scripts_dir                            = undef,
  $service_fqdn                           = $::fqdn,
  $ssh_conf_file_contents                 = undef,
  $statsd_host                            = undef,
  $statsd_port                            = undef,
  $user                                   = 'nodepool',
) {

  $packages = [
    'git',
    'nodepool',
    'python-diskimage-builder',
    'vhd-util',
  ]

  ensure_packages($packages)

  group { $user:
    ensure => 'present',
  }

  $user_home_dir = '/var/lib/nodepool'
  $project_config_user_home_dir = '/var/lib/project-config-cloner'

  user { $user :
    ensure     => 'present',
    home       => $user_home_dir,
    shell      => '/bin/false',
    gid        => $user,
    system     => true,
    managehome => true,
    require    => Group[$user],
  }

  if($project_config_clone_ssh_key_file) {
    group { $project_config_user:
      ensure => 'present',
    }
    user { $project_config_user :
      ensure     => 'present',
      home       => $project_config_user_home_dir,
      shell      => '/bin/false',
      gid        => $project_config_user,
      system     => true,
      managehome => true,
      require    => Group[$project_config_user],
    }
    file { "${project_config_user_home_dir}/.ssh" :
      ensure  => 'directory',
      mode    => '0700',
      owner   => $project_config_user,
      group   => $project_config_user,
      require => [
        User[$project_config_user],
      ],
    }
    if($project_config_known_hosts) {
      create_resources('ssh::known_host', $project_config_known_hosts, {
        user    => $project_config_user,
        require => File[ "${project_config_user_home_dir}/.ssh" ],
      })
    }
    file { $project_config_clone_ssh_key_file_path :
      owner   => $project_config_user,
      group   => $project_config_user,
      mode    => '0400',
      content => $project_config_clone_ssh_key_file,
      require => File["${project_config_user_home_dir}/.ssh"],
    }

    if ($project_config_repo) {
      vcsrepo { $project_config_cfg_dir :
        ensure   => 'latest',
        provider => git,
        identity => $project_config_clone_ssh_key_file_path,
        revision => $project_config_repo_revision,
        source   => $project_config_repo,
        user     => $project_config_user,
        group    => $project_config_user,
        owner    => $project_config_user,
        require  => [
          Package['git'],
          User[$project_config_user],
          File[$project_config_clone_ssh_key_file_path],
        ]
      }

      file { $project_config_sync_script_path :
        ensure  => 'present',
        content => template('nodepool/project_config_sync_script.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
      }
    }
    if($project_config_cron_jobs) {
      create_resources(cron, $project_config_cron_jobs, {
        ensure      => 'present',
        user        => $project_config_user,
        require     => User[$project_config_user],
      })
    }
  }

  if($cron_jobs) {
    create_resources(cron, $cron_jobs, {
      ensure      => 'present',
      user        => $user,
      require     => User[$user],
    })
  }

  file { $config_dir:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
  }

  file { "${config_dir}/nodepool.yaml" :
    ensure  => 'link',
    target  => $project_config_nodepool_yaml_path,
    owner   => $user,
    group   => $user,
    mode    => '0400',
    require => [
      File[$config_dir],
      User[$user],
    ],
  }

  if ($scripts_dir) {
    file { "${config_dir}/scripts" :
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => '0755',
      recurse => true,
      purge   => true,
      force   => true,
      require => File[$config_dir],
      source  => $scripts_dir,
    }
  }

  if ($elements_dir) {
    file { "${config_dir}/elements" :
      ensure  => 'directory',
      owner   => $user,
      group   => $user,
      mode    => '0755',
      recurse => true,
      purge   => true,
      force   => true,
      require => File[$config_dir],
      source  => $elements_dir
    }
  }

  file { '/etc/default/nodepool':
    ensure  => 'present',
    content => template('nodepool/nodepool.default.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  file { $dib_dir :
    ensure  => 'directory',
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  }

  file { $dib_cache_dir :
    ensure  => 'directory',
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  }

  file { $dib_tmp_dir :
    ensure  => 'directory',
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  }

  file { '/var/log/nodepool':
    ensure  => 'directory',
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  }

  file { '/var/run/nodepool':
    ensure  => 'directory',
    mode    => '0755',
    owner   => $user,
    group   => $user,
    require => User[$user],
  }

  file { "${user_home_dir}/.ssh" :
    ensure  => 'directory',
    mode    => '0700',
    owner   => $user,
    group   => $user,
    require => [
      User[$user],
    ],
  }
  if($known_hosts) {
    create_resources('ssh::known_host', $known_hosts, {
        user    => $user,
        require => File[ "${user_home_dir}/.ssh" ],
    })
  }
  file { "${user_home_dir}/.ssh/id_rsa" :
    ensure  => 'present',
    content => $nodepool_ssh_private_key_contents,
    mode    => '0400',
    owner   => $user,
    group   => $user,
    require => [
      User[$user],
      File["${user_home_dir}/.ssh"],
    ],
  }

  if ($ssh_conf_file_contents) {
    file { "${user_home_dir}/.ssh/config" :
      ensure  => 'present',
      content => $ssh_conf_file_contents,
      mode    => '0440',
      owner   => $user,
      group   => $user,
      require => File["${user_home_dir}/.ssh"],
    }
  }

  file { "${config_dir}/logging.conf" :
    ensure  => 'present',
    mode    => '0440',
    owner   => $user,
    group   => $user,
    content => template('nodepool/nodepool.logging.conf.erb'),
  }

  service { 'nodepool':
    ensure     => 'running',
    name       => 'nodepool',
    enable     => true,
    hasrestart => true,
    require    => [
      Package['nodepool'],
    ],
  }

  if ($enable_image_log_via_http) {
    include ::nginx
    file { '/var/www' :
      ensure  => 'directory',
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      require => Package['nginx-full'],
    }
    file { '/var/www/nodepool' :
      ensure  => 'directory',
      mode    => '0755',
      owner   => $user,
      group   => $user,
      require => [
        User[$user],
        File['/var/www/'],
        Package['nginx-full'],
      ],
    }
    file { $image_log_document_root:
      ensure  => 'directory',
      mode    => '0755',
      owner   => $user,
      group   => $user,
      require => [
        User[$user],
        File['/var/www/nodepool'],
      ],
    }
    ::nginx::resource::vhost { 'image-logs' :
      ensure      => 'present',
      autoindex   => 'on',
      listen_port => 80,
      server_name => [$service_fqdn, $::fqdn],
      www_root    => $image_log_document_root,
      access_log  => $nginx_access_log,
      error_log   => $nginx_error_log,
      format_log  => $nginx_log_format,
      require     => File[$image_log_document_root],
    }
  }

}
