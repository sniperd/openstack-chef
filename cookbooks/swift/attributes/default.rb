default[:swift][:user] = "swift"
default[:swift][:group] = "swift"
default[:swift][:homedir] = "/home/swift"
default[:swift][:ppa_uri] = "http://ppa.launchpad.net/swift-core/release/ubuntu" # Note: Over time this will change and update 3FD32ED0E38B0CFA59495557C842BD46562598B4
default[:swift][:ppa_key] = "3FD32ED0E38B0CFA59495557C842BD46562598B4"
#default[:swift][:ppa_uri] = "http://ppa.launchpad.net/openstack-release/2011.3/ubuntu" # Older PPA 

default[:swift][:storage][:online] = true

default[:swift][:auth][:password] = "testpass" #TODO: should be in an encrypted data bag or out of band, Look at https://github.com/gholt/swauth if you want swauth
default[:swift][:auth][:auth_type] = "tempauth" # Note: tempauth is for dev, swauth is for production, Leave this alone if your unsure
default[:swift][:auth][:repo] = "git@github.com:gholt/swauth.git"
default[:swift][:auth][:clone_dir] = "/usr/src/swauth"

default[:swift][:ssl][:country] = 'US'
default[:swift][:ssl][:state] = 'MA'
default[:swift][:ssl][:city] = 'Boston'
default[:swift][:ssl][:company] = 'Sonian, Inc'
default[:swift][:ssl][:email] = 'chefs@sonian.net'
default[:swift][:ssl][:domain] = 'sonian.net'
default[:swift][:ssl][:department] = 'DEVOPS'

default[:swift][:hash_path_suffix] = "2d851a6c3564e2"

default[:swift][:device_names] = ["/dev/mapper/ebs-swift"] # Note: This should be set to an array of block devices on the storage servers on which swift can write its data

default[:swift][:super_admin_key] = "swauth"

default[:swift][:ring_common][:account_part_power] = 18
default[:swift][:ring_common][:account_replicas] = 3
default[:swift][:ring_common][:account_min_part_hours] = 1

default[:swift][:ring_common][:container_part_power] = 18
default[:swift][:ring_common][:container_replicas] = 3
default[:swift][:ring_common][:container_min_part_hours] = 1

default[:swift][:ring_common][:object_part_power] = 18
default[:swift][:ring_common][:object_replicas] = 3
default[:swift][:ring_common][:object_min_part_hours] = 1

default[:swift][:ring_types] = ["account", "container", "object"]

default[:swift][:account][:port] = 6002
default[:swift][:account][:weight] = 100
default[:swift][:account][:meta] = "install"

default[:swift][:container][:port] = 6001
default[:swift][:container][:weight] = 100
default[:swift][:container][:meta] = "install"

default[:swift][:object][:port] = 6000
default[:swift][:object][:weight] = 100
default[:swift][:object][:meta] = "install"
