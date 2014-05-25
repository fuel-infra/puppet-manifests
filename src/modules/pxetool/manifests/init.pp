class pxetool {
  include nginx
  include uwsgi

  include pxetool::params

  $additional_repos = $pxetool::params::additional_repos
  $config = $pxetool::params::config
  $mirror = $pxetool::params::mirror
  $packages = $pxetool::params::packages

  package { $packages :
    ensure => latest,
  }

  file { $config :
    path => $config,
    ensure => 'present',
    mode => '0600',
    owner => 'www-data',
    content => template('pxetool/pxetool.py.erb'),
  }

  Package[$packages]->
    File[$config]~>
    Class['uwsgi']
}
