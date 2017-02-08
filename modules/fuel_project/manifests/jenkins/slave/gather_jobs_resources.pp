# Class: fuel_project::jenkins::slave::gather_jobs_resources
#
# Class with requirements to run gather_jobs_resources_stats job.
#
class fuel_project::jenkins::slave::gather_jobs_resources {
  $packages = [
    'python-2.7',
    'python-jenkins',
    'python-mysqldb',
    'python-requests',
    'python-sqlalchemy',
    'python-sqlalchemy-ext',
  ]

  ensure_packages($packages)
}
