# Class: ssh::client
#
# This class configures SSH client for some user(s).
#
# Parameters:
#
#   [*configs*]
#     Hash containing user configuration:
#     All connection parameters, are optional. If 'host' is not defined,
#     connection name will be used as hostname.
#     Other parameters will be skipped if undefined.
#
#     ssh::client::configs:
#       root:
#         connections:
#           connection_1:
#             host: host.name.tld
#             port: 29418
#             user: remote_user
#             private_key_contents: |
#               -----BEGIN RSA PRIVATE KEY-----
#               ...
#               -----END RSA PRIVATE KEY-----
#           connection_2:
#             ...
#           '*':
#             user: default_remote_username
#             private_key_contents: |
#               -----BEGIN RSA PRIVATE KEY-----
#               ... Default SSH key ...
#               -----END RSA PRIVATE KEY-----
#       other_user:
#         connections:
#           ...
#
#
class ssh::client (
  $configs = hiera_hash('ssh::client::configs'),
  ) {

  ensure_packages('facter-facts-user-homes')

  create_resources(ssh::client_config, $configs)

}
