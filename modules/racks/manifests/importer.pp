# Define: racks::importer
#
# This class setups Cron entries for Racks application.
#
# Parameters:
#   [*options*] - importer configuration file entries
#     Example:
#      'instances':
#        'example-ci.infra.org':
#          'racks_url': 'https://racks.infra.org'
#          'racks_application': 'jenkins-importer'
#          'racks_auth_token': 'xyz123456'
#          'jenkins_url': 'https://example.infra.org'
#          'jenkins_user': 'racktables-importer'
#          'jenkins_token': 'xyz654321'
#          'label_tag': 'exampleci'
#   [*cron*] - cron entries to create
#     Example:
#       'jenkins-importer':
#         'minute': '*/5'
#   [*files*] - files to create
#     Example:
#       '/etc/ssl/certs/some-importer.crt':
#         'content': |
#           -----BEGIN CERTIFICATE-----
#           abcdefghijklmnopqrstuwxyz12
#           -----END CERTIFICATE-----
#   [*package*] - Boolean, should we install importer package or not.
#
define racks::importer (
  $options = hiera_hash("racks::importer::${title}::options", {}),
  $cron = hiera_hash("racks::importer::${title}::cron", {}),
  $files = hiera_hash("racks::importer::${title}::files", {}),
  $package = false,
) {
  package { "python-django-racks-importer-${title}" :}

  if($package) {
    Package <| title == "python-django-racks-importer-${title}" |> {
      ensure => 'latest',
    }
  } else {
    Package <| title == "python-django-racks-importer-${title}" |> {
      ensure => 'absent',
    }
  }
  file { "/etc/racks/importers/${title}.yaml" :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('racks/importer_config.yaml.erb'),
    require => Package["python-django-racks-importer-${title}"]
  }

  if ($cron) {
    # flock && logger
    ensure_packages(['util-linux', 'bsdutils'])
    create_resources('cron', $cron, {
      ensure  => 'present',
      command => "/usr/bin/flock -xn /var/lock/racks-importer-${title}.lock /usr/share/racks/importers/${title}.py 2>&1 | /usr/bin/logger -t ${title}-importer",
      require => [
        Package['util-linux'],
        Package["python-django-racks-importer-${title}"],
      ],
    })
  }

  if ($files) {
    create_resources('file', $files, {
      mode  => '0400',
      owner => 'root',
      group => 'root',
    })
  }
}
