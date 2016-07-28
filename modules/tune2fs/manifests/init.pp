# Class: tune2fs
#
# Parameters:
#   [*tune2fs*] - Hash, options to pass to tune2fs module
#     $tune2fs = {
#       '/dev/vda1' => {
#         'action' => 'reserved_percentage',
#         'value'  => '0.5',
#     }
#
class tune2fs ($tune2fs) {
  create_resources('::tune2fs', $tune2fs, {})
}
