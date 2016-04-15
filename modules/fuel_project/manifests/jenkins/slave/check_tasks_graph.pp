# Class: fuel_project::jenkins::slave::check_tasks_graph
#
# Class sets up check_tasks_graph role
#
class fuel_project::jenkins::slave::check_tasks_graph {
  $packages = [
    'python-pytest',
    'python-jsonschema',
    'python-networkx',
  ]

  ensure_packages($packages)
}
