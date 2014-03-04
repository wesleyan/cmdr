# Copyright (C) 2014 Wesleyan University
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/env /usr/local/rvm/bin/rvm-auto-ruby

require 'cgi'
require 'cgi/session'
require 'socket'

cgi = CGI.new('html4')

session = CGI::Session.new(cgi)

def tp6(cgi, path="../tp6")
puts cgi.header
file = File.open(path, 'r')
file.each do |line|
  puts line
end
file.close
end

#def local_ip
#  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
#
#  UDPSocket.open do |s|
#    s.connect '64.233.187.99', 1
#    s.addr.last
#  end
#ensure
#  Socket.do_not_reverse_lookup = orig
#end

#server_ip = local_ip

if cgi.remote_addr == "127.0.0.1"
  tp6 cgi
elsif session['valid'] == 1
  tp6(cgi, "../tp6_remote")
else
  puts cgi.header('Status' => '302 Moved', 'Location' => '../login.html')
end
