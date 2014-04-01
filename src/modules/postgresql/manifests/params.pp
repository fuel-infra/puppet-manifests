class postgresql::params {
  if $::operatingsystem == 'Ubuntu' {
    if $::operatingsystemrelease == '12.04' {
      $config = '/etc/postgresql/9.1/main/pg_hba.conf'
    }
    elsif $::operatingsystemrelease == '14.04' {
      $config = '/etc/postgresql/9.3/main/pg_hba.conf'
    }
  }
  $packages = [
    'postgresql'
  ]
  $service = 'postgresql'
}
