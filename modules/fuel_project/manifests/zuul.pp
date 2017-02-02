# Class: fuel_project::zuul
#
# This class deploys Zuul Zabbix items and configures automatic update of Zuul layout.
#
# Parameters:
#   [*config_update_method*] - Choose the configuration files update methood: jenkins or repository.
#   [*jenkins_job*] - Name of Jenkins project that prepares configs.
#   [*jenkins_url*] - URL of Jenkins instance where to get updated configs.
#   [*project_config_cfg_dir*] - Project-config root directory
#   [*project_config_clone_ssh_key_file*] - SSH private file content for the user which has rights accessint the project-config repo.
#   [*project_config_clone_ssh_key_file_path*] - Path to ssh private key which stores key used for accessing the project-config repo.
#   [*project_config_cron_jobs*] - hash for creating cron jobs
#   [*project_config_repo*] - Url to the project-config repo
#   [*project_config_repo_revision*] - Revision to use during the project-repo cloning
#   [*project_config_sync_script_path*] - Path to the script which fetches project-config's repository
#   [*project_config_user*] - Username to use when cloning project-config repo
#   [*project_config_user_home_dir*] - Path to project-config-cloner user home directory.
#   [*project_config_zuul_ext_funct_path*] - Path to the external_functions.py file
#   [*project_config_zuul_yaml_path*] - Zuul layout file path in project-config dir
#   [*update_cronjob_name*] - Name of cron job updating zuul layout.
#   [*update_cronjob_params*] - Hash containing parameters of cron job.
#   [*zuul_layout* ] - Path to Zuul layout file.
#
class fuel_project::zuul (
  $config_update_method                   = 'jenkins',
  $jenkins_job                            = 'zuul-maintainer',
  $jenkins_url                            = 'http://jenkins.server.name/',
  $project_config_cfg_dir                 = '/etc/project-config',
  $project_config_clone_ssh_key_file      = undef,
  $project_config_clone_ssh_key_file_path = '/var/lib/project-config-cloner/.ssh/id_rsa',
  $project_config_cron_jobs               = undef,
  $project_config_repo                    = undef,
  $project_config_repo_revision           = 'master',
  $project_config_sync_script_path        = '/usr/local/bin/project_config_sync.sh',
  $project_config_user                    = 'project-config-cloner',
  $project_config_user_home_dir           = '/var/lib/project-config-cloner',
  $project_config_zuul_ext_funct_path     = '/etc/project-config/zuul/external_functions.py',
  $project_config_zuul_yaml_path          = '/etc/project-config/zuul/layout.yaml',
  $update_cronjob_name                    = 'update_zuul_layout',
  $update_cronjob_params                  = {},
  $zuul_layout                            = hiera('zuul::layout'),
){
  ensure_resource('class', 'zabbix::agent')
  ensure_packages('config-zabbix-agent-zuul-item')

  if($project_config_clone_ssh_key_file) {
    group { $project_config_user :
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
      require => User[$project_config_user],
    }
    file { $project_config_clone_ssh_key_file_path :
      owner   => $project_config_user,
      group   => $project_config_user,
      mode    => '0400',
      content => $project_config_clone_ssh_key_file,
      require => File["${project_config_user_home_dir}/.ssh"],
    }
  }

  if ($project_config_repo) {
    ensure_packages('git')
    file { $project_config_cfg_dir :
      ensure  => 'directory',
      mode    => '0755',
      owner   => $project_config_user,
      group   => $project_config_user,
      require => User[$project_config_user],
    }
    file { $project_config_sync_script_path :
      ensure  => 'present',
      content => template('fuel_project/zuul/project_config_sync_script.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
    exec { 'project-config-sync-script' :
      cwd       => '/tmp',
      command   => $project_config_sync_script_path,
      logoutput => 'on_failure',
      user      => $project_config_user,
      require   => [
        File[$project_config_cfg_dir],
        File[$project_config_clone_ssh_key_file_path],
        File[$project_config_sync_script_path],
        User[$project_config_user],
        Package['git'],
      ],
    }
    if ($project_config_cron_jobs) {
      create_resources(cron, $project_config_cron_jobs, {
        ensure      => 'present',
        user        => $project_config_user,
        require     => User[$project_config_user],
      })
    }
  }

  file { '/usr/local/bin/zuul_apply_layout.sh':
    mode    => '0755',
    content => template('fuel_project/zuul/zuul_apply_layout.sh.erb'),
  }
  create_resources('cron', { "${update_cronjob_name}" => $update_cronjob_params }, {
    ensure      => 'absent',
    environment => 'PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin',
    command     => '/usr/bin/flock -xn /var/lock/update_zuul_layout.lock /usr/local/bin/zuul_apply_layout.sh 2>&1 | logger -t update-zuul-layout',
    user        => 'zuul',
    minute      => '*/30',
  })

}
