# Class: pxetool::smart_proxy
#
# This class installs Trivial File Transfer Protocol Server package.
#
class pxetool::smart_proxy {
  $packages = [
    'tftp-hpa',
  ]
  ensure_packages($packages)
}
