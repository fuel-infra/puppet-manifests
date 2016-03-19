# Class: fuel_project::apps::rss2irc
#
# This class deploys notifier which forwards RSS to IRC.
#
# Hiera parameters:
#   [*instances*] - connection pairs
#    Example:
#      instances:
#        'test-redirect':
#          'rss': 'https://infra-ci.fuel-infra.org/rssAll'
#          'nick': 'fuel-test'
#          'channel': 'fuel-test'
#
class fuel_project::apps::rss2irc (
  $instances  = {},
) {
  # install rss2irc package
  ensure_packages('rss2irc')

  include ::supervisord

  # definition of specific supervisord entries for rss2irc
  define instance (
    $channel,
    $nick,
    $rss,
    $options = '-i 1 -l',
    $server = 'chat.freenode.net',
  ) {

    $parameters = "${options} ${rss} ${server}/${channel}/${nick}"

    supervisord::program { $title:
      command  => "/usr/bin/rss2irc ${parameters}",
      priority => '100',
    }
  }

  # create instances as defined in parameter
  create_resources(instance, $instances)
}
