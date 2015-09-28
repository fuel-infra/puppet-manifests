# Define: racks::importer
#
define racks::importer (
  $options = hiera_hash("racks::importer::${title}::options", {}),
  $cron = hiera_hash("racks::importer::${title}::cron", {}),
  $files = hiera_hash("racks::importer::${title}::files", {}),
) {
  ensure_packages(["python-django-racks-importer-${title}"])
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
