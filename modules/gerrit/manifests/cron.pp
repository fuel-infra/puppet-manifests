# Class: gerrit::cron
#
# This class deploys cron entries which are required by Gerrit.
class gerrit::cron {

  cron { 'gerrit_repack':
    user        => 'gerrit',
    weekday     => '0',
    hour        => '4',
    minute      => '7',
    command     => 'find /var/lib/gerrit/review_site/git/ -type d -name "*.git" -print -exec git --git-dir="{}" repack -afd \;',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
  }

  cron { 'expireoldreviews':
    ensure => 'absent',
    user   => 'gerrit',
  }

  cron { 'removedbdumps':
    ensure => 'absent',
    user   => 'gerrit',
  }
}
