# Anonymous statistics test suite
class fuel_project::statistics::tests {
    $packages = [
      'python-tox',
    ]
    ensure_packages($packages)
    if (!defined(Class['postgresql::server'])) {
      class { 'postgresql::server' : }
    }

    postgresql::server::db { 'collector':
      user     => 'collector',
      password => 'collector',
    }
    file { '/var/log/fuel-stats' :
      ensure  => directory,
      owner   => 'jenkins',
      require => User['jenkins'],
    }
}
