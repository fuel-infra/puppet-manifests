# Class: fuel_project::apps::inventory
#
# This class deploys a fully functional inventory application.
#
# Parameters:
#   [*importers*] - defines many different types of importers required by racks
#     Example:
#      'jenkins':
#       'options':
#         'instances':
#           'example-ci.infra.org':
#             'racks_url': 'https://racks.infra.org'
#             'racks_application': 'jenkins-importer'
#             'racks_auth_token': 'xyz123456'
#             'jenkins_url': 'https://example.infra.org'
#             'jenkins_user': 'racktables-importer'
#             'jenkins_token': 'xyz654321'
#             'label_tag': 'exampleci'
#
class fuel_project::apps::inventory (
  $importers = {},
) {
  class { '::racks::webapp' :}
  create_resources('::racks::importer', $importers)
}
