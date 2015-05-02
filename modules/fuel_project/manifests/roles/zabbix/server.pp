# Class: fuel_project::roles::zabbix::server
#
class fuel_project::roles::zabbix::server (
  $mysql_replication_password = '',
  $mysql_replication_user     = 'repl',
  $mysql_slave_host           = undef,
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
  }
}
