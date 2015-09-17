# Class: fuel_project::apps::inventory
#
class fuel_project::apps::inventory (
  $importers = {},
) {
  class { '::racks::webapp' :}
  create_resources('::racks::importer', $importers)
}
