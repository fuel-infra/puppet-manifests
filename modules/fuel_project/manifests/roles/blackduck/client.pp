# Class: fuel_project::roles::blackduck::server::client
#
# This class is about configuration of Blackduck's client.
#
# Parameters:
#   [*google_creds*] - hash to have an ability to work with Google services
#    (Google Drive, for example).
#    Hash in the following form:
#     type: 'service_account'
#     private_key_id: 'put_here_your_id'
#     private_key: 'put_here_your_key'
#     client_email: 'put_here_your_client_email'
#     client_id: 'put_here_your_client_id'
#     auth_uri: 'https://accounts.google.com/o/oauth2/auth'
#     token_uri: 'https://accounts.google.com/o/oauth2/token'
#     auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs'
#     client_x509_cert_url: 'put_here_your_client_x509_cert_url'
#    [*sdk_dst*] - string, path to directory where SDK should be unpacked
#    [*sdk_path*] - string, path to director where SDK's distr is placed
#    [*ssh_private_key*] - string, value of private ssh-key
#    [*ssh_private_key_path*] - string, path to directory to store private ssh-key
#
class fuel_project::roles::blackduck::client (
  $google_creds          = hiera_hash('fuel_project::roles::blackduck::client::google_creds', undef),
  $sdk_dst               = '/home/jenkins/',
  $sdk_path              = '/mnt/Export-SDK.zip',
  $ssh_private_key       = undef,
  $ssh_private_key_path  = '/home/jenkins/.ssh'
) {

  $dependencies = [
    'dpkg-dev',
    'libblackduck-sampledoanalysis-java',
    'libblackduck-sampleupdatesourcedirectory-java',
    'python-grab',
    'python-gspread',
    'python-oauth2client',
    'python-selection',
    'python-simplejson',
    'python-user-agent',
    'reprepro',
    'rpm',
    'rsync',
    'unzip',
    'weblib',
  ]

  if ($dependencies) {
    ensure_packages($dependencies)
  }

  file { "${ssh_private_key_path}/id_rsa" :
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    content => $ssh_private_key,
    replace => true,
    require => File[$ssh_private_key_path],
  }

  file { $sdk_dst:
    ensure => 'directory',
  }

  exec { 'unzip_sdk':
    command => "/usr/bin/unzip ${sdk_path} -d ${sdk_dst}",
    user    => 'jenkins',
    require => [
      Package[$dependencies],
      File[$sdk_dst],
      User['jenkins']
    ],
  }

  file { '/etc/blackduck' :
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0600',
  }

  file { '/etc/blackduck/credentials.json':
    ensure  => 'present',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0400',
    content => template('fuel_project/roles/blackduck/credentials.json.erb'),
    require => [
      File['/etc/blackduck'],
    ]
  }

}
