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

cgi = CGI.new('html4')
session = CGI::Session.new(cgi)

session.delete()

puts cgi.header('Status' => '302 Moved', 'Location' => '../login.html')
