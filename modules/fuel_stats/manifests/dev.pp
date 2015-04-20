# dev configuration for anonymous statistics
define fuel_stats::dev (
  $repo_url = 'https://github.com/stackforge/fuel-stats/',
  $dest_dir = "/var/www/${title}",
  $requirements = "/var/www/${title}/${title}/requirements.txt",
  $user = $title,
  $auto_update = true,
  $packages = [],
) {
  $dev_packages = [
    'python-pip',
    'git',
    'libpq-dev',
    'libpython-dev',
    'python-git', # github-poller.py
  ]

  $all_packages = concat($dev_packages, $packages)
  ensure_packages($all_packages)

  # github poller script
  if ! defined(File['/usr/local/bin/github-poller.py']) {
    file { '/usr/local/bin/github-poller.py':
      source => 'puppet:///modules/fuel_stats/github-poller.py',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  if ! defined(User[$user]) {
    user { $user:
      home       => $dest_dir,
      managehome => false,
      system     => true,
      shell      => '/usr/sbin/nologin',
    }
  }

  if ! defined(File['/var/www']) {
    file { '/var/www':
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  file { $dest_dir :
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0755',
    require => [
      Package[$all_packages],
      User[$user],
      File['/var/www'],
    ],
  }

  exec { "clone-github-${title}":
    command     =>
    "/usr/bin/git clone ${repo_url} ${dest_dir}",
    require     => [
      Package[$all_packages],
      User[$user],
    ],
    refreshonly => true,
    subscribe   => File[$dest_dir],
  }

  exec { "install-${title}-requirements" :
    command => "/usr/bin/pip install -r ${requirements}",
    require => [
      Exec["clone-github-${title}"],
      Package[$all_packages],
    ],
    onlyif  => "test -e ${requirements}",
  }

  if ($auto_update) {
    # cronjob
    cron { "github-poller-${title}":
      command     =>
        'flock -n -x /tmp/github-poller.lock /usr/local/bin/github-poller.py 2>&1 | logger -t github-poller',
      environment => "REPO_LOCAL=${dest_dir}",
      user        => 'root',
      hour        => '*',
      minute      => ['0', '15', '30', '45'],
      require     => [
        File['/usr/local/bin/github-poller.py'],
        Exec["clone-github-${title}"],
      ],
    }
  }
}
