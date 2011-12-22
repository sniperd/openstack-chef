name 'swift_proxy_server'
description 'swift proxy server'

run_list %w{
  recipe[swift::default]
  recipe[swift::proxy]
}

default_attributes :swift => {
  :proxy => true
}
