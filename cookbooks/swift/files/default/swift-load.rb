#!/usr/bin/env ruby
require 'rubygems'
require 'cloudfiles'
cf = CloudFiles::Connection.new(:username => "system:root", :api_key => "testpass", :auth_url => "https://127.0.0.1:8080/auth/v1.0")
puts cf.containers

#
# Check out swift-bench for metrics, this is just a stub for API access
#

