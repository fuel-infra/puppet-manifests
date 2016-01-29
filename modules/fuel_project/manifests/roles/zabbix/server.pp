# Class: fuel_project::roles::zabbix::server
#
# This class deploys Zabbix server role.
#
# Parameters:
#   [*mysql_replication_password*] - MySQL replication password
#   [*mysql_replication_user*] - MySQL replication user
#   [*mysql_slave_host*] - MySQL slave host
#   [*maintenance_cron*] - maintanance script run Cron entries
#   [*maintenance_script*] - maintanance script path
#   [*maintenance_script_config*] - maintanance script MySQL config
#   [*server_role*] - server mode
#   [*slack_emoji_ok*] - Slack Emoji OK icon code
#   [*slack_emoji_problem*] - Slack Emoji PROBLEM icon code
#   [*slack_emoji_unknown*] - Slack Emoji UNKNOWN icon code
#   [*slack_post_username*] - Slack user name for posting
#   [*slack_web_hook_url*] - Slack web hook URL
#
class fuel_project::roles::zabbix::server (
  $mysql_replication_password = '',
  $mysql_replication_user     = 'repl',
  $mysql_slave_host           = undef,
  $maintenance_cron           = {
    'zabbix-maintenance' => {
      hour => '*/24',
    },
  },
  $maintenance_script         = '/usr/share/zabbix-server-mysql/maintenance.sh',
  $maintenance_script_config  = '/root/.my.cnf',
  $server_role                = 'master', # master || slave
  $slack_emoji_ok             = ':smile:',
  $slack_emoji_problem        = ':frowning:',
  $slack_emoji_unknown        = ':ghost:',
  $slack_post_username        = '',
  $slack_web_hook_url         = '',
) {
  class { '::fuel_project::common' :}
  class { '::zabbix::server' :}

  ::zabbix::server::alertscript { 'slack.sh' :
    template => 'fuel_project/zabbix/slack.sh.erb',
    require  => Class['::zabbix::server'],
  }

  ::zabbix::server::alertscript { 'zabbkit.sh' :
    template => 'fuel_project/zabbix/zabbkit.sh.erb',
    require  => Class['::zabbix::server'],
  }

  if ($server_role == 'master' and $mysql_slave_host) {
    mysql_user { "${mysql_replication_user}@${mysql_slave_host}" :
      ensure        => 'present',
      password_hash => mysql_password($mysql_replication_password),
    }

    mysql_grant { "${mysql_replication_user}@${mysql_slave_host}/*.*" :
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['REPLICATION SLAVE'],
      table      => '*.*',
      user       => "${mysql_replication_user}@${mysql_slave_host}",
    }

    file { $maintenance_script :
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('fuel_project/roles/zabbix/server/maintenance.sh.erb'),
      require => Class['::zabbix::server'],
    }

    create_resources('cron', $maintenance_cron, {
      ensure  => 'present',
      command => "${maintenance_script} 2>&1 | logger -t zabbix-maintenance",
    })
  }
}
