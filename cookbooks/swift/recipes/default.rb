#
# Cookbook Name:: swift
# Recipe:: default
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

include_recipe 'apt'

package "python-software-properties"

apt_repository "openstack-release" do
  uri node.swift.ppa_uri
  keyserver "keyserver.ubuntu.com"
  key node.swift.ppa_key 
  distribution node[:lsb][:codename]
  components ["main"]
  action :add
end

package "swift"

user "swift" do
  supports :manage_home => true
  action [ :lock, :manage, :modify ]
  home "/home/swift"
  shell "/bin/bash"
  comment "Openstack Swift User"
  system true
end

directory "/etc/swift" do
  owner node.swift.user
  group node.swift.group
  mode "0755"
end

template "/etc/swift/swift.conf" do 
  owner node.swift.user
  group node.swift.group
  mode "0600"
  variables( :hash_path_suffix => node.swift.hash_path_suffix )
end

directory "/home/swift/.ssh" do
  owner node.swift.user
  group node.swift.group
  recursive true
  mode "0755"
end

#
# Note: you should run ssh-keygen and replace all of these keys at a minimum, if not figure out a better way to propogate these and contribute back
#

%w{ config id_rsa authorized_keys }.each do |key|
  cookbook_file "/home/swift/.ssh/#{key}" do
    owner "swift"
    group "swift"
    mode "0600"
  end
end

#
# Note: This is a hack to get around python-netifaces blowing up when it find interfaces that do not have IP Addresses (in this case on AWS EC2, but it could happen on others), This should be some random ip you will never need not in your subnets.
# If you have a problem with netifaces, set a random ip in a subnet you will never contact onto the interface
#
#execute "ifconfig eql 192.168.0.250" do 
#  not_if "ifconfig eql|grep inet"
#end 
