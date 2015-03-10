#
class fuel_project::fuel_docs(
  $firewall_enable   = false,
  $nginx_server_name = 'fuel-docs.test.local',
  $fuel_version      = '6.0',
  $ssh_auth_key      = undef,
) {
  class { '::fuel_project::common' :
    external_host => $firewall_enable,
  }

  if $ssh_auth_key {
    ssh_authorized_key { 'fuel_docs@jenkins' :
      user => 'root',
      type => 'ssh-rsa',
      key  => $ssh_auth_key,
    }
  }

  class { '::fuel_project::nginx' : }

  ::nginx::resource::vhost { 'fuel-docs' :
    ensure              => 'present',
    server_name         => $server_name,
    listen_port         => 80,
    www_root            => '/var/www',
    location_cfg_append => {
      'rewrite' => {
        "^/fuel/\$"           => "/fuel/fuel-${fuel_version}",
        "^/openstack/fuel/\$" => "/openstack/fuel/fuel-${fuel_version}",
      },
    }
  }

  if ! defined(File['/var/www']) {
    file { '/var/www' :
      ensure => 'directory',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }
  }

  file { '/var/www/robots.txt' :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('fuel_project/fuel_docs/robots.txt.erb'),
    require => File['/var/www'],
  }

  if $firewall_enable {
    include firewall_defaults::pre
    create_resources(firewall, '1000 - allow http traffic', {
      dport   => 80,
      action  => 'accept',
      require => Class['firewall_defaults::pre'],
    })
  }
}
