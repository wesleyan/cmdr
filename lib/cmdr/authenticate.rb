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

require 'yaml'
require 'openssl'
module Authenticate
  def Authenticate.get_credentials(path="#{File.dirname(__FILE__)}/../..")
    credentials = YAML::load_file "#{path}/credentials.yml"
    key = YAML::load_file "#{path}/key.yml"

    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = key["key"]
    decipher.iv = key["iv"]

    pw = decipher.update(credentials["password"]) + decipher.final
    auth = {"user" => credentials["user"], "password" => pw}
  end
end
