#!/usr/bin/env ruby

require 'cgi'
require 'cgi/session'
require 'couchrest'
require 'digest'

def error
  puts "LOGIN FAILED: Incorrect username/password"
  exit
end

cgi = CGI.new("html4")

#Safely create a new session
begin
  session = CGI::Session.new(cgi, 'new_session' => false)
  session.delete
rescue ArgumentError
end

session = CGI::Session.new(cgi, 'new_session' => true)

@username = cgi.has_key?('user') ? cgi['user'].to_s : ''
@password = cgi.has_key?('password') ? cgi['password'].to_s : ''


@db = CouchRest.database("http://localhost:5984/roomtrol-users")

@db.all_docs["rows"].each do |row|
  if row['username'] == @username
    @userData = row
    break
  end
end

if @doc.nil?
  error
end

@hash = Digest::SHA256.digest(@userData['salt'] + Digest::SHA256.digest(@password))

if @hash != @userData['password']
  error
else
  session['valid'] = 1
end
