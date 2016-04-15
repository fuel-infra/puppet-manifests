# Class: fuel_project::jenkins::slave::verify_jenkins_jobs
#
# Class sets up verify_jenkins_jobs role
#
class fuel_project::jenkins::slave::verify_jenkins_jobs {
  $packages = [
    'python-tox',
    'shellcheck',
  ]

  ensure_packages($packages)
}
