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

#require 'cmdr/socketclient'
require 'strscan'
require 'rubybits'
require 'socket'
require 'eventmachine'

def send_event severity 
      @_event = {"device" => "#{@hostname}", 
                 "component" => "#{@name}", 
                 "location" => "#{configuration[:uri]}",
                 "title" => "Communication lost with #{@name}",
                 "description" => "Communication lost with #{@name}", 
                 "device_type" => "/Status/Device",
                 "time" => Time.new,
                 "severity" => severity}
      EM.defer do
        begin
          DaemonKit.logger.info("Received error: #{@_event}")
          serv = XMLRPC::Client.new2('http://localhost:5000/messages/')
          serv.call('sendEvent', @_event)
        rescue
        end
      end
    end

def operational= operational
  self.operational = operational
  if self.operational
    send_event 0
  else
    send_event 5
  end
end
