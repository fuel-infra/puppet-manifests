# Define: racks::importer
#
define racks::importer (
  $options = hiera_hash("racks::importer::${title}", {})
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

  if is_hash($options['cron']) {
    ensure_packages(['util-linux', 'bsdutils'])
    create_resources('cron', $options['cron'], {
      ensure  => 'present',
      command => "/usr/bin/flock -xn /var/lock/racks-importer-${title}.lock /usr/share/racks/importers/${title}.py 2>&1 | /usr/bin/logger -t ${title}-importer",
      require => [
        Package['util-linux'],
        Package["python-django-racks-importer-${title}"],
      ],
    })
  }
}
