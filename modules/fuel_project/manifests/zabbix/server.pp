# Class: fuel_project::zabbix::server
#
class fuel_project::zabbix::server (
  $slack_web_hook_url = '',
  $slack_post_username = '',
  $slack_emoji_ok = ':smile:',
  $slack_emoji_problem = ':frowning:',
  $slack_emoji_unknown = ':ghost:',
) {
  class { '::fuel_project::common' :}
  class { '::zabbix::server' :}

  ::zabbix::server::alertscript { 'slack.sh' :
    template => 'fuel_project/zabbix/slack.sh.erb',
  }
}
