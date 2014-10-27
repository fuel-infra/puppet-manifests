# Class: fuel_project::nginx
#
class fuel_project::nginx {
  if (!defined(Class['::nginx'])) {
    class { '::nginx' :}
  }

  ::nginx::resource::vhost { 'stub_status' :
    ensure              => 'present',
    listen_port         => '127.0.0.1:61929',
    location_custom_cfg => {
      stub_status => true,
    },
  }
}
