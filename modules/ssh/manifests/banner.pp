# Class: ssh::banner
#
class ssh::banner (
  $content = '',
) {
  file { '/etc/banner' :
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => $content,
  }
}
