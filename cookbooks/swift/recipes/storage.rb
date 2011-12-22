#
# Cookbook Name:: swift
# Recipe:: storage
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

%w{xfsprogs swift-account swift-container swift-object}.each do |pkg_name|
  package pkg_name
end

node.swift.device_names.each do |full_device_name|
  device_name = full_device_name.split("/").last

  partition_path_name = full_device_name.include?("mapper") ? full_device_name : full_device_name + "1"


  execute "partition disk" do
    command "/bin/echo -e \',,L\\n;\\n;\\n;\' | /sbin/sfdisk #{full_device_name}"
    not_if "xfs_admin -u #{partition_path_name}"
  end

  execute "build filesystem" do
    command "mkfs.xfs -i size=1024 #{partition_path_name}"
    not_if "xfs_admin -u #{partition_path_name}"
  end

  directory "/srv/node/" do
    owner node.swift.user 
    group node.swift.group
    recursive true
    mode "0755"
  end

  directory "/srv/node/#{device_name}" do
    owner node.swift.user 
    group node.swift.group
    recursive true
    mode "0755"
  end

  mount "/srv/node/#{device_name}" do
    device partition_path_name
    fstype "xfs"
    options "noauto,noatime,nodiratime,nobarrier,logbufs=8"
    action [ :enable, :mount ]
  end
end

template "/etc/rsyncd.conf"

cookbook_file "/etc/default/rsync" do
  source "default-rsync"
end

service "rsync" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

%w{/etc/swift/object-server /etc/swift/container-server /etc/swift/account-server /var/run/swift}.each do |new_dir|
  directory new_dir do
    recursive true
    owner node.swift.user
    group node.swift.group
    recursive true
    mode "0755"
  end
end

node.swift.ring_types.each do |server_type|
  template "/etc/swift/#{server_type}-server.conf" do
    mode "0644"
    owner node.swift.user
    group node.swift.group
    variables(:disable_mount_check => node.swift.device_names.collect{|dn| dn.include?("mapper")}.include?(true)) # Swift has issues using LVM as the block storage on the back end.
  end
end

%w{ swift-object swift-object-replicator swift-object-updater swift-object-auditor swift-container swift-container-replicator swift-container-updater swift-container-auditor swift-account swift-account-replicator swift-account-auditor }.each do |component|
  service component do
    supports :restart => true, :reload => true, :start => true, :stop => true, :status => false
    action [ :enable, :start ]
  end
end
