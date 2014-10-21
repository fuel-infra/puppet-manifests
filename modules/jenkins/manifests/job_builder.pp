# == Class: jenkins::job_builder
#
class jenkins::job_builder (
  $url = $::jenkins::params::job_builder_url,
  $username = $::jenkins::params::job_builder_username,
  $password = $::jenkins::params::job_builder_password,
  $packages = $::jenkins::params::job_builder_packages,
) inherits ::jenkins::params {
  ensure_packages($packages)

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }

  file { '/etc/jenkins_jobs/jenkins_jobs.ini':
    ensure  => present,
    mode    => '0400',
    content => template('jenkins/jenkins_jobs.ini.erb'),
    require => File['/etc/jenkins_jobs'],
  }
}
