#!/usr/bin/env ruby
require 'cgi'
require 'cgi/session'

cgi = CGI.new('html4')
session = CGI::Session.new(cgi)

session.delete()

print cgi.header('Status' => '302 Moved', 'Location' => 'index.html')
