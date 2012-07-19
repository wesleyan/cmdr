#!/usr/bin/env ruby

require 'cgi'
require 'couchrest'
require 'digest'
require 'digest/md5'
require 'uuidtools'

def error e
  puts "Registration Error: #{e}"
  exit
end

cgi = CGI.new("html4")

@username = cgi.has_key?('user') ? cgi['user'].to_s : ''
@password = cgi.has_key?('password') ? cgi['password'].to_s : '' 
@pass2 = cgi.has_key?('pass2') ? cgi['pass2'].to_s : ''

if @username == '' or @password == ''
  error "All forms need to be filled out!"
end
if @password != @pass2
  error "Passwords do not match!"
end
if @username.length > 30
  error "Username must be fewer than 30 characters!"
end

@salt = SecureRandom.hex[0..2]
@hash = Digest::SHA256.digest(@salt + Digest::SHA256.digest(@password))

@db = CouchRest.database("http:localhost:5984/roomtrol-users")
@doc = {"user" => "#{@username}", "password" => "#{@hash}", "salt" => "#{@salt}"}

@db.save_doc @doc
