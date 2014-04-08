class nginx::share {
  include nginx

  $fqdn = $::fqdn
  $service = $nginx::params::service

  file { 'share.conf' :
    path => '/etc/nginx/sites-enabled/share.conf',
    ensure => present,
    mode => '0644',
    owner => 'root',
    group => 'root',
    content => template('nginx/share.conf.erb'),
  }

  File['share.conf']~>
    Service[$service]
}
