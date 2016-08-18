# Defined type ssh::private_key
#
# This type defines SSH private keys placed into individual files named like 'user@server'.
#
# Parameters:
#   [*home*] - Home directory of user for whom creating private key(s)
#   [*owner*] - Username of user for whom creating private key(s)
#   [*host*] - Remote host
#   [*port*] - Portnumber on remote host to connect
#   [*private_key_contents*] - Contents of SSH private key
#   [*user*] - Remote username
#
define ssh::private_key (
  $home,
  $owner,
  $host                 = $title,
  $port                 = undef,
  $private_key_contents = undef,
  $user                 = undef,
  ) {

  if ( $private_key_contents ) {

    if ( $user ) {
      $_user_part = "${user}@"
    } else {
      $_user_part = ''
    }

    if ( $port ) {
      $_port_part = "_${port}"
    } else {
      $_port_part = ''
    }

    if ( $title == '*' ) {
      $_key_filename = "${home}/.ssh/id_rsa"
    } else {
      $_key_filename = "${home}/.ssh/id_rsa.${_user_part}${host}${_port_part}"
    }

    file { $_key_filename:
      owner   => $owner,
      mode    => '0400',
      content => $private_key_contents,
    }
  }

}
