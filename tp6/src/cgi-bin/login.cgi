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
require 'couchrest'
require 'digest'
require 'iconv'
require '../ruby/authenticate'

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

@creds = Authenticate.get_credentials("../security")
@credentials = "#{@creds['user']}:#{@creds['password']}"

@db = CouchRest.database("http://#{@credentials}@localhost:5984/cmdr-users")

@db.all_docs["rows"].each do |row|
  row = @db.get(row["id"]).to_hash
  if row['user'] == @username
    @userData = row
    break
  end
end

if @userData.nil?
  puts cgi.header
  error
end

@hash = Digest::SHA256.digest(@userData['salt'] + Digest::SHA256.digest(@password))
@hash = Iconv.iconv('utf-8', 'iso8859-1', @hash)[0]

if @hash != @userData['password']
  puts cgi.header
  error
else
  session['valid'] = 1
  puts cgi.header('Status' => "302 Moved", 'Location' => 'tp6.cgi')
end
