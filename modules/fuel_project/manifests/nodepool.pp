# == Class: fuel_project::nodepool
#
# This class deploys Nodepool instance.
#
# Nodepool itself must be installed by module ::nodepool, then this module
# does several things:
#
#   - configures SSH client for accessing managed VMs
#   - creates database
#   - configures `secure.conf`
#   - fetches contents for project-config using SSH private key if given
#   - installs elements, scripts, and nodepool.yaml from project-config
#   - enables and runs services
#
# === Parameters
#
# [*db_name*]
#   Name of database for Nodepool
#   Required. Default: `nodepool`
#
# [*db_user*]
#   Username for nodepool database
#   Required. Default: `nodepool`
#
# [*db_pass*]
#   Password of database user `db_user`
#   Required. Default: none
#
# [*jenkins_targets*]
#   A hash containing definitions of Jenkins targets (to maintain secure.conf)
#   Optional. Default: none
#
#   See: http://docs.openstack.org/infra/nodepool/configuration.html#configuration
#
#   jenkins_targets => {
#     jenkins_server => {
#       url: 'https://jenkins.domain.tld/'
#       user: 'jenkins'
#       apikey: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
#       credentials: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
#
# [*vm_ssh_private_key_contents*]
#   SSH private key contents for managed VMs
#   Optional. Default: none
#
# [*$project_config_update_method*]
#   Method to get and update project-config (the project containig nodepool configuration)
#   At the moment the only supported method is `puppet`
#   Optional. Default: `puppet`
#
# [*project_config_ssh_private_key_contents*]
#   SSH private key contents to be used for fetching project-config
#   Optional. Default: none
#
# === Examples
#
# The only required parameter with no default value is `db_pass`, so minimal
# declaration must contain it:
#
#   class { 'fuel_project::nodepool':
#     db_pass => 'my_very_secure_and_long_enough_password',
#   }
#
# === Authors
#
# Alexander Evseev <aevseev@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis, Inc.
#
class fuel_project::nodepool (
  ## Database parameters
  $db_name                                 = 'nodepool',
  $db_user                                 = 'nodepool',
  $db_pass                                 = undef,

  ## Jenkins targets for secure.conf
  $jenkins_targets                         = {},

  ## Private SSH key for accessing managed VMs
  $vm_ssh_private_key_contents             = undef,

  ## project-config update parameters
  $project_config_update_method            = 'puppet',
  $project_config_ssh_private_key_contents = undef,
){

  require ::nodepool

  $nodepool_user  = getparam( Class['::nodepool'], 'nodepool_user' )
  $nodepool_group = getparam( Class['::nodepool'], 'nodepool_group' )
  $nodepool_home  = getparam( Class['::nodepool'], 'nodepool_home' )
  $log_dir        = getparam( Class['::nodepool'], 'log_dir' )

  if ( $db_pass == undef ) {
    fail("\nError: Module '${module_name}': Password for database is required (\$db_pass)\n\t")
  }

  file { '/etc/nodepool':
    ensure => directory,
  }

  ## Configure SSH client for acessing VMs
  if ( $vm_ssh_private_key_contents ) {
    if ( ! defined( File["${nodepool_home}/.ssh"] ) ) {
      file { "${nodepool_home}/.ssh":
        ensure => directory,
        owner  => $nodepool_user,
      }
    }
    file { "${nodepool_home}/.ssh/id_rsa":
      ensure  => present,
      owner   => $nodepool_user,
      mode    => '0600',
      content => $vm_ssh_private_key_contents,
    }
  }

  ## Create (builder-)logging.conf
  file { '/etc/nodepool/logging.conf':
    content => template('fuel_project/nodepool/logging.conf.erb'),
  }
  file { '/etc/nodepool/builder-logging.conf':
    content => template('fuel_project/nodepool/builder-logging.conf.erb'),
  }

  ## Create secure.conf
  $_dburi = "mysql://${db_user}:${db_pass}@/${db_name}"

  file { '/etc/nodepool/secure.conf':
    owner   => $nodepool_user,
    group   => $nodepool_group,
    mode    => '0400',
    content => template('fuel_project/nodepool/secure.conf.erb'),
  }

  ## Prepare database
  mysql::db { $db_name:
    user     => $db_user,
    password => $db_pass,
  }

  class { 'mysql::server':
    override_options => {
      mysqld => {
        default_storage_engine        => 'InnoDB',
        innodb_file_per_table         => 1,
        innodb_file_format            => 'barracuda',
        log_queries_not_using_indexes => 1,
        max_connections               => 8196,
        slow_query_log                => 1,
        slow_query_log_file           => '/var/log/mysql/slow.log',
      },
    },
  }

  ## Install default database driver for MySQL
  $_pkg_db_client_mysql = $::osfamily ? {
    'Debian' => 'python-mysqldb',
    'RedHat' => 'MySQL-python',
    'Suse'   => 'python-MySQL-python',
  }
  ensure_packages([ $_pkg_db_client_mysql ])

  case $project_config_update_method {
  'puppet': {
    ## Module project_config can't handle SSH keys, but it can use
    ## existing directory
    vcsrepo { '/etc/project-config':
      ensure   => latest,
      provider => git,
      source   => hiera('project_config::url'),
      revision => hiera('project_config::revision'),
      notify   => Class['project_config'],
    }

    if ( $project_config_ssh_private_key_contents ) {
      file { '/root/id_rsa.project_config':
        ensure  => present,
        content => $project_config_ssh_private_key_contents,
        mode    => '0600',
      }
      Vcsrepo['/etc/project-config'] {
        identity => '/root/id_rsa.project_config',
      }
    } else {
      file { '/root/id_rsa.project_config':
        ensure => absent,
      }
    }

    include project_config
    anchor { 'project_config_start': } -> Class['::project_config'] -> anchor { 'project_config_stop': }

    ## Required config files
    file { '/etc/nodepool/elements':
      ensure    => directory,
      purge     => true,
      recurse   => true,
      source    => $project_config::nodepool_elements_dir,
      subscribe => Vcsrepo['/etc/project-config'],
    }

    file { '/etc/nodepool/scripts':
      ensure    => directory,
      purge     => true,
      recurse   => true,
      source    => $project_config::nodepool_scripts_dir,
      subscribe => Vcsrepo['/etc/project-config'],
    }

    file { '/etc/nodepool/nodepool.yaml':
      ensure    => present,
      source    => $project_config::nodepool_config_file,
      subscribe => Vcsrepo['/etc/project-config'],
    }
  } # 'puppet'
  default: {
    fail("Module '${module_name}': Unknown project-config update method - '${project_config_update_method}'")
  } # default
  } # case

  ## Enable services
  $_nodepool_services = [ 'nodepool', 'nodepool-builder' ]
  service { $_nodepool_services:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Mysql::Db[$db_name],
    subscribe  => [
      File['/etc/nodepool/nodepool.yaml'],
      File['/etc/nodepool/secure.conf'],
      Class['os_client_config'],
    ],
  }

}
