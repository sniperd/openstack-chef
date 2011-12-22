#
# Cookbook Name:: swift
# Recipe:: proxy
#
# Author: Josh Pasqualetto <josh.pasqualetto@sonian.net>
#
# Copyright 2011-2012, Sonian.net Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "swift-proxy"
package "memcached"

template "/etc/swift/ssl_cert.conf" do 
  owner node.swift.user
  group node.swift.group
  variables(:country => node.swift.ssl.country,
            :province => node.swift.ssl.state,
            :city => node.swift.ssl.city,
            :company => node.swift.ssl.company,
            :email => node.swift.ssl.email,
            :department => node.swift.ssl.department,
            :domain => node.swift.ssl.domain)
end

execute "Create SSL Certificates" do 
  cwd "/etc/swift"
  command "openssl req -new -x509 -nodes -out cert.crt -keyout cert.key -config /etc/swift/ssl_cert.conf"
  not_if "test -e /etc/swift/cert.crt"
  environment( { 'KEY_COUNTRY' => node.swift.ssl.country,     
                  'KEY_PROVINCE' => node.swift.ssl.state, 
                  'KEY_CITY' => node.swift.ssl.city, 
                  'KEY_ORG' => node.swift.ssl.company, 
                  'KEY_EMAIL' => node.swift.ssl.email, 
                  'KEY_CN' =>  node.swift.ssl.domain } )
end

template "/etc/memcached.conf" do
  variables(:ip_address => node.ipaddress)
  notifies :restart, "service[memcached]"
end

service "swift-proxy" do
    supports :start => true, :restart => true, :restart => true
      action [ :enable, :start ]
end

service "memcached" do
    supports :status => true, :start => true, :stop => true, :restart => true
      action [ :enable, :start ]
end

template "/etc/swift/proxy-server.conf" do
  owner node.swift.user 
  group node.swift.group
  mode "0644"
  variables(:ip_address => node.ipaddress)
  notifies :restart, "service[swift-proxy]"
end

node.swift.ring_types.each do |ringtype|
  execute "Builing #{ringtype} ring" do
    command "swift-ring-builder /etc/swift/#{ringtype}.builder create " + 
    node[:swift][:ring_common]["#{ringtype}_part_power".to_sym].to_s + " " +
      node[:swift][:ring_common]["#{ringtype}_replicas".to_sym].to_s + " " +
      node[:swift][:ring_common]["#{ringtype}_min_part_hours".to_sym].to_s 
    not_if "test -f /etc/swift/#{ringtype}.builder"
  end
end
storage_nodes = search(:node, "role:swift_storage_server")

storage_nodes.each do |swift_server|
  if swift_server[:swift][:storage][:online] 
    log "Found Storage node marked ONLINE #{swift_server.name} w/ IP: #{swift_server.ipaddress}"
    swift_server.swift.device_names.each do |full_device_name|
      device_name = full_device_name.split("/").last

      node.swift.ring_types.each do |ring_type|
        log "swift-ring-builder /etc/swift/" + ring_type + ".builder add z" + swift_server[:swift][:zone].to_s + '-' + swift_server.ipaddress + ":" + swift_server[:swift][ring_type.to_sym][:port].to_s + "/" + device_name + "_" + swift_server[:swift][ring_type.to_sym][:meta] + " " + swift_server[:swift][ring_type.to_sym][:weight].to_s + "; exit 0"
        execute "add #{swift_server.ec2.local_ipv4} #{swift_server.ec2.instance_id} to #{ring_type}" do
          cwd "/etc/swift"
          command "swift-ring-builder /etc/swift/" + ring_type + ".builder add z" + swift_server[:swift][:zone].to_s + '-' + swift_server.ipaddress + ":" + swift_server[:swift][ring_type.to_sym][:port].to_s + "/" + device_name + "_" + swift_server[:swift][ring_type.to_sym][:meta] + " " + swift_server[:swift][ring_type.to_sym][:weight].to_s + "; exit 0"
          notifies :run, "execute[rebalance the #{ring_type} ring]"
          not_if do
            metaname = "z" + swift_server[:swift][:zone].to_s + '-' + swift_server.ipaddress + ":" + swift_server[:swift][ring_type.to_sym][:port].to_s + "/" + device_name + "_" + swift_server[:swift][ring_type.to_sym][:meta].to_s
            `echo blah > /tmp/blee && cd /etc/swift && swift-ring-builder #{ring_type}.builder search #{metaname}`
            $? == 256   # Why is this 256?  It's what works, but I don't know why.
          end
        end
      end
    end
  end
end

node.swift.ring_types.each do |ringtype|
  execute "rebalance the #{ringtype} ring" do
    cwd '/etc/swift/'
    command "swift-ring-builder /etc/swift/#{ringtype}.builder rebalance; exit 0" 
    storage_nodes.map { |sn| notifies :run, "execute[scp rings to #{sn.ipaddress}]" }
    action :nothing
  end
end

storage_nodes.each do |storage_node|
  execute "scp rings to #{storage_node.ipaddress}" do
    user "swift"
    cwd '/etc/swift/'
    command "scp /etc/swift/*.builder /etc/swift/*.gz swift@#{storage_node.ipaddress}:/etc/swift/"
    action :nothing
  end
end

if node.swift.auth.auth_type == "swauth"
  include_recipe "swift::swauth" #Otherwise tempauth is used
end
