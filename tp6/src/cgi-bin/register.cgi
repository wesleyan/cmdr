#!/usr/bin/env /usr/local/rvm/bin/rvm-auto-ruby

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

require 'cgi'
require 'couchrest'
require 'digest'
require 'digest/md5'
require 'uuidtools'
require '../ruby/authenticate'

def error e
  puts "Registration Error: #{e}"
  exit
end

cgi = CGI.new("html4")

@username = cgi.has_key?('user') ? cgi['user'].to_s : ''
@password = cgi.has_key?('password') ? cgi['password'].to_s : '' 
@pass2 = cgi.has_key?('pass2') ? cgi['pass2'].to_s : ''

if @username == '' or @password == ''
  puts cgi.header
  error "All forms need to be filled out!"
end
if @password != @pass2
  puts cgi.header
  error "Passwords do not match!"
end
if @username.length > 30
  puts cgi.header
  error "Username must be fewer than 30 characters!"
end

@salt = SecureRandom.hex[0..2]
@hash = Digest::SHA256.digest(@salt + Digest::SHA256.digest(@password))
@hash = @hash.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => "?")

@creds = Authenticate.get_credentials("../security")
@credentials = "#{@creds['user']}:#{@creds['password']}"

@db = CouchRest.database("http://#{@credentials}@localhost:5984/cmdr-users")
@doc = CouchRest::Document.new({"user" => @username, "password" => @hash, "salt" => @salt})

@db.save_doc @doc

puts cgi.header('Status' => '302 Moved', 'Location' => '../index.html')
