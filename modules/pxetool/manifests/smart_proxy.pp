# Smart proxy for pxetool
class pxetool::smart_proxy {
  $packages = [
    'tftp-hpa',
  ]
  ensure_packages($packages)
}
