#
# Cookbook Name:: swift
# Recipe:: swauth
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

git node.swift.auth.clone_dir do
  repository node.swift.auth.repo
  reference 'master'
  action :sync
end

execute "Install swauth module for swift" do
  command "python setup.py install && swift-init proxy reload"
  cwd node.swift.auth.clone_dir
  creates "/usr/local/bin/swauth-prep"
end
