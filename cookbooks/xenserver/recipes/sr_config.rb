#
# Cookbook Name:: xenserver
# Recipe:: sr_config
#
# Copyright 2011, Rackspace
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#----

#So make sure your SR is Thin Provisioned when creating it.  It needs to be
#an ext3 type SR instead of LVMVHD.
#
#$XE sr-param-set uuid="$SR" name-label="slices"
       #$XE sr-param-set uuid="$SR"
#other-config:i18n-original-value-name_label="slices"

sr_name_label = node[:xenserver][:sr_name_label]

bash "configure SR i18n keys" do
  user "root"
  code <<-EOH
	UUID=$(xe sr-list name-label="#{sr_name_label}" | grep uuid | sed -e 's|.*: ||')
	[ -n "$UUID" ] || exit 1
	xe sr-param-set uuid=$UUID other-config:i18n-key=local-storage
	xe sr-param-set uuid=$UUID other-config:i18n-original-value-name_label="#{sr_name_label}"
  EOH
  not_if "UUID=$(xe sr-list name-label='#{sr_name_label}' | grep uuid | sed -e 's|.*: ||'); xe sr-param-list uuid=$UUID | grep local-storage"
end
