#!/usr/bin/env /usr/local/rvm/bin/ruby
require 'cgi'
require 'cgi/session'
require 'socket'

cgi = CGI.new('html4')

session = CGI::Session.new(cgi)

def tp6(cgi)
puts cgi.header
file = File.open("../tp6", 'r')
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
  tp6 cgi
else
  puts cgi.header('Status' => '302 Moved', 'Location' => '../login.html')
end
