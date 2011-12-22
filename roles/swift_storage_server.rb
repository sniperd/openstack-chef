name 'swift_storage_server'
description 'swift storage server'

run_list %w{
  recipe[swift::default]
  recipe[swift::storage]
}
