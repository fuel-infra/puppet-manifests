# Definition ssh::key_group
#
# Definition of key_group which applies mapping to SSH key entries.
#
define ssh::key_group ($key_group = $title) {
  $keys = hiera_hash("common::infra::${key_group}::ssh_keys", {})
  create_resources(ssh::key_group::pair, $keys)
}
