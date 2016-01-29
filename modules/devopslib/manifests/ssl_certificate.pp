# Definition: devopslib::ssl_certificate
#
# This definition get cerificate from hiera and creates it on destination
# system.
#
# Hiera usage:
# ---
# ssl_certificates::sample_cert:
#   crt:
#     filename: '/etc/ssl/cert.crt'
#     content: |
#       -----BEGIN CERTIFICATE-----
#       ...
#       -----END CERTIFICATE-----
#   key:
#     filename: '/etc/ssl/cert.key'
#     content: |
#       -----BEGIN RSA PRIVATE KEY-----
#       ...
#       -----END RSA PRIVATE KEY-----
#
# In puppet manifests:
# devopslib::ssl_certificate { 'sample_cert':
#   owner => 'www-data'
# }
#
define devopslib::ssl_certificate(
  $certificate = hiera_hash("ssl_certificates::${title}"),
  $owner       = 'root',
  $group       = 'root',
  $mode        = '0400',
) {
  file { $certificate['crt']['filename'] :
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $certificate['crt']['content'],
  }
  file { $certificate['key']['filename'] :
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => $certificate['key']['content'],
  }
}
